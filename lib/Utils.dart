class Utils {
  static String monthToString(int month) {
    switch (month) {
      case 1 : return "jan";
      case 2 : return "feb";
      case 3 : return "mar";
      case 4 : return "apr";
      case 5 : return "may";
      case 6 : return "jun";
      case 7 : return "jul";
      case 8 : return "aug";
      case 9 : return "sep";
      case 10 : return "oct";
      case 11 : return "nov";
      default : return "dec";
    }
  }
}