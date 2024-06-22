import socket
import threading
from concurrent.futures import ThreadPoolExecutor, wait, FIRST_COMPLETED
import numpy as np
import time
import cv2
dummy = 1 # if you can't run a vision model locally
if not dummy:
    import torch
    from ultralytics import YOLO
line_ind = 0
plot_frames = 0
traj_lines = []
host = "127.0.0.1"
port = 12345
classes_of_interest = [0] # 0=person
#Available objects for detection {0: 'person', 1: 'bicycle', 2: 'car', 3: 'motorcycle', 4: 'airplane', 5: 'bus', 6: 'train', 7: 'truck', 8: 'boat', 9: 'traffic light', 10: 'fire hydrant', 11: 'stop sign', 12: 'parking meter', 13: 'bench', 14: 'bird', 15: 'cat', 16: 'dog', 17: 'horse', 18: 'sheep', 19: 'cow', 20: 'elephant', 21: 'bear', 22: 'zebra', 23: 'giraffe', 24: 'backpack', 25: 'umbrella', 26: 'handbag', 27: 'tie', 28: 'suitcase', 29: 'frisbee', 30: 'skis', 31: 'snowboard', 32: 'sports ball', 33: 'kite', 34: 'baseball bat', 35: 'baseball glove', 36: 'skateboard', 37: 'surfboard', 38: 'tennis racket', 39: 'bottle', 40: 'wine glass', 41: 'cup', 42: 'fork', 43: 'knife', 44: 'spoon', 45: 'bowl', 46: 'banana', 47: 'apple', 48: 'sandwich', 49: 'orange', 50: 'broccoli', 51: 'carrot', 52: 'hot dog', 53: 'pizza', 54: 'donut', 55: 'cake', 56: 'chair', 57: 'couch', 58: 'potted plant', 59: 'bed', 60: 'dining table', 61: 'toilet', 62: 'tv', 63: 'laptop', 64: 'mouse', 65: 'remote', 66: 'keyboard', 67: 'cell phone', 68: 'microwave', 69: 'oven', 70: 'toaster', 71: 'sink', 72: 'refrigerator', 73: 'book', 74: 'clock', 75: 'vase', 76: 'scissors', 77: 'teddy bear', 78: 'hair drier', 79: 'toothbrush'}
# Note: small objects like scissors might not be detected well. read more about the  bizarre set of objects that can be detected here: https://cocodataset.org/#home
SLEEP_TIME = 0.0001
CONF = 0.35
cam_width = 1280
cam_height = 720
do_y_pos_corr = 1
do_x_pos_corr = 1
debug_timing = 1
st=0
global keep_running

def load_dummy_trajectories(path='../resources/dummy_trajecories.txt'):
    global traj_lines
    with open(path,'r') as h:
        traj_lines=h.readlines()
    #traj_lines=[elem.strip() for elem in traj_lines]


def create_server_socket(host="127.0.0.1", port=12345):
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server_socket.bind((host, port))
    server_socket.listen()
    print(f"{host}:{port} - Waiting for client...")
    return server_socket


def correct_ypos(locs):
    out = []
    for loc in locs:
        close_to_0 = (cam_height-loc[1])/cam_height
        correction = close_to_0 * loc[3]/2
        loc[1] = loc[1] + correction
        out.append(loc)
    return out

def correct_xpos(locs):
    out = []
    middle=cam_width/2
    for loc in locs:
        if loc[0]<middle:

            close_to_left = (cam_width/2-loc[0])/(cam_width/2) # 1 if left, 0 if center
            correction = close_to_left * loc[2]/2
        else:
            close_to_right = abs(cam_width/2-loc[0])/(cam_width/2) # 1 if right, 0 if center
            correction = - close_to_right * loc[2]/2
        loc[0] = loc[0] + correction
        out.append(loc)
    return out


def parse_results(results):
    try:
        if not dummy:
            out = 'Nothing'
            inds = np.where([elem in classes_of_interest for elem in results[0].boxes.cls.cpu().numpy()])[0]
            if len(inds) > 0:
                # print(ind)
                mask = [e in classes_of_interest for e in results[0].boxes.cls]
                res = results[0][mask].boxes
                if len(res):

                    classes = res.cls.cpu().numpy()
                    ids = [0] if res.id is None else res.id.cpu().numpy()
                    confs = res.conf.cpu().numpy()
                    locs = res.xywh.cpu().numpy()
                    if do_y_pos_corr:
                        locs = correct_ypos(locs)
                    if do_x_pos_corr:
                        locs = correct_xpos(locs)
                    out = ''
                    for i in range(len(ids)):
                        out += str([ids[i], classes[i], confs[i]] + list(locs[i]))+','
                        # output structure: [id,cls,conf,x,y,w,h],[.....],[.....]
                    out = out[:-1]
            return out+'\n'
        else: # dummy mode
            global line_ind, traj_lines
            line_ind += 1
            if line_ind == len(traj_lines):
                line_ind=0
            return str(traj_lines[line_ind])
    except Exception as e:
        print(res,e)

def send_data(data, client_socket):
    global keep_running
    try:
        client_socket.sendall(data)
        client_socket.settimeout(1)  # Timeout after 5 seconds
    except BrokenPipeError:
        keep_running=False
    try:
        ack = client_socket.recv(1024).decode('utf-8').strip()
        if ack == "ACK":
            print("Acknowledgment received")
        else:
            print(ack, ack.strip())
            print("Unexpected response received")
    except socket.timeout:
        print("No acknowledgment received within timeout period")
    except BrokenPipeError:
        print('broken')
        keep_running=0

def main():
    global  keep_running
    keep_running=True
    st = time.time()
    if not dummy:
        torch.cuda.set_device(0)
        model = YOLO('yolov8m.pt') # load a computer vision detection model.
        if torch.cuda.is_available():
            model.cuda()
            print('using gpu')
    else:
        load_dummy_trajectories()
    server_socket = create_server_socket(host, port)

    client_socket, addr = server_socket.accept()
    client_socket.settimeout(0.0001)

    print("Got a connection from %s" % str(addr))

    if not dummy:
        vid = cv2.VideoCapture(0)
        vid.set(3, cam_width)
        vid.set(4, cam_height)
        ok, frame = vid.read()
    try:

        executor = ThreadPoolExecutor(max_workers=5)
        while keep_running:
            loop_time = time.time()-st
            # print(loop_time)
            st = time.time()
            # check_socket_status(client_socket)
             # Adjust max_workers as needed

            if not dummy:
                ok, frame = vid.read()
                if cam_height==720:
                    frame=np.concatenate((frame, np.zeros((960 - 720, 1280, 3), dtype='uint8')))
            else:
                ok=True
            if ok:
                if not dummy:
                    results = model.track(frame, persist=True, conf=CONF, stream=False,imgsz=cam_width)
                    # Visualize the results on the frame
                    if plot_frames:
                        annotated_frame = results[0].plot()
                        # Display the annotated frame
                        cv2.imshow("YOLOv8 Tracking", annotated_frame)
                    r = parse_results(results)
                else:
                    r = parse_results(None)
                data = r.encode('utf-8')
                # st=time.time()
                # send_data(data, client_socket)
                executor.submit(send_data, data, client_socket)
                # print('taken ',time.time()-st)
                time.sleep(SLEEP_TIME)  # Delay

            # if cv2.waitKey(1) & 0xFF == ord('q'):  # this adds latency, remove if issues arise.
            #     client_socket.close()
            #     break
    except BrokenPipeError:
        print('client closed')
    finally:
        executor.shutdown(wait=False)
        client_socket.close()
        if not dummy:
            vid.release()
        cv2.destroyAllWindows()


if __name__ == '__main__':
    main()