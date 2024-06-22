class Logger {
  String logFileName;
  PrintWriter logWriter;
  
  Logger(String fileName) {
    logFileName = fileName;
    logWriter = createWriter(logFileName);
    log("Logger started");
  }
  
  void log(String message) {
    String timestamp = getTimestamp();
    String logMessage = timestamp + " - " + message;
    println(logMessage); // Print to console
    logWriter.println(logMessage); // Write to log file
    logWriter.flush(); // Ensure the message is written immediately
  }
  
  String getTimestamp() {
    int year = year();
    int month = month();
    int day = day();
    int hour = hour();
    int minute = minute();
    int second = second();
    return nf(year, 4) + "-" + nf(month, 2) + "-" + nf(day, 2) + " " + nf(hour, 2) + ":" + nf(minute, 2) + ":" + nf(second, 2);
  }
  
  void close() {
    log("Logger ended");
    logWriter.flush();
    logWriter.close();
  }
}
