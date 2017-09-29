import {Observable} from 'rxjs';


export function makeConsoleDriver() {

  return function consoleDriver(sink$) {
    sink$.subscribe( (i) => {
      console.log('console: ' + i);
    });
  }
}
