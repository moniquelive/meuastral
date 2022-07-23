import './main.css';
import './datepicker.css';
import './zodiac.css';
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';

const USER_BIRTHDAY_LOCAL_STORAGE_KEY = 'user-birthday';
const user_birthday = localStorage.getItem(USER_BIRTHDAY_LOCAL_STORAGE_KEY);

const app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: user_birthday
});

app.ports.storeDoB.subscribe(function(birthday) {
  localStorage.setItem(USER_BIRTHDAY_LOCAL_STORAGE_KEY, birthday);
});

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();
