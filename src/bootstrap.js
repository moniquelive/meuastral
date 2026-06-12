const USER_BIRTHDAY_LOCAL_STORAGE_KEY = 'user-birthday';
const userBirthday = localStorage.getItem(USER_BIRTHDAY_LOCAL_STORAGE_KEY);
const locale =
  window.__MEUASTRAL_LOCALE__ ||
  navigator.languages?.[0] ||
  navigator.language ||
  'pt-BR';

const app = Elm.Main.init({
  node: document.getElementById('root'),
  flags: {
    userBirthday,
    locale
  }
});

app.ports.storeDoB.subscribe(function(birthday) {
  localStorage.setItem(USER_BIRTHDAY_LOCAL_STORAGE_KEY, birthday);
});
