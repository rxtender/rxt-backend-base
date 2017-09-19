import {Observable} from 'rxjs';


export function makeConsoleDriver() {

  return function consoleDriver(sink$) {
    console.log("created consoleDriver: " + sink$);
    sink$.subscribe( (i) => {
      console.log('console: ' + i);
    });
  }
}
