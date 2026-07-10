const USER_BIRTHDAY_LOCAL_STORAGE_KEY = 'user-birthday';

function readStoredBirthday() {
  try {
    return window.localStorage.getItem(USER_BIRTHDAY_LOCAL_STORAGE_KEY);
  } catch (error) {
    return null;
  }
}

function storeBirthday(birthday) {
  try {
    window.localStorage.setItem(USER_BIRTHDAY_LOCAL_STORAGE_KEY, birthday);
  } catch (error) {
    // The reading still works when storage is blocked or unavailable.
  }
}

const root = document.getElementById('root');
const userBirthday = readStoredBirthday();
const locale =
  window.__MEUASTRAL_LOCALE__ ||
  navigator.languages?.[0] ||
  navigator.language ||
  'pt-BR';

if (root && window.Elm?.Main) {
  const app = window.Elm.Main.init({
    node: root,
    flags: {
      userBirthday,
      locale
    }
  });

  app.ports.storeDoB.subscribe(storeBirthday);
}
