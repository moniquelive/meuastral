const USER_BIRTHDAY_LOCAL_STORAGE_KEY = 'user-birthday';
const user_birthday = localStorage.getItem(USER_BIRTHDAY_LOCAL_STORAGE_KEY);

const app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: user_birthday
});

app.ports.storeDoB.subscribe(function(birthday) {
  localStorage.setItem(USER_BIRTHDAY_LOCAL_STORAGE_KEY, birthday);
});
