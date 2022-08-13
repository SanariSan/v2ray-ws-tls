{
  const load = () => {
    var uuid = document.createElement('script');
    uuid.src = 'https://unpkg.com/uuid@latest/dist/umd/uuidv5.min.js';
    document.getElementsByTagName('head')[0].appendChild(uuid);
  };
  const sleep = (m) => new Promise((r) => setTimeout(r, m));
  const gen = (keywords, pk) => keywords.forEach((kw) => console.log(`${kw} | ${uuidv5(kw, pk)}`));

  // -------------------------------------------------------------

  const keywords = ['user1', 'user2', 'user3'];
  const pk = '1b9d6bcd-bbfd-4b2d-9b5d-ab8dfbbd4bed';

  Promise.resolve()
    .then(load)
    .then(() => sleep(3000))
    .then(() => gen(keywords, pk));
}
