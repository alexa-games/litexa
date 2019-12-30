let a = "bob"
let b = 10

switch (a) {
  case "bob" + (b == 10 ? '' : 'X'): {
    console.log("good");
    break;
  }
  default: {
    console.log("bad");
    break;
  }
}

switch (v) {
  case BASEVALUE:
    break;
  case BASEVALUE + 1:
    break;
  case BASEVALUE + 2:
    break;
}
