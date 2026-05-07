'use strict';
const MANIFEST = 'flutter-app-manifest';
const TEMP = 'flutter-temp-cache';
const CACHE_NAME = 'flutter-app-cache';

const RESOURCES = {"flutter_bootstrap.js": "f3f6da3f492950c6c89f577c5fe83527",
"version.json": "1b9113546028f5eff5f73b56c8a3c82d",
"googleb91878f2b0f4b57b.html": "9421914e5bd9cf0ee977af645c73396a",
"index.html": "19432020073347df1417b66fcb7588ca",
"/": "19432020073347df1417b66fcb7588ca",
"main.dart.js": "de6e7bbcb94db4c425ad01c39aa32146",
"flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"cors.json": "3b412ca14a1ba2cb8f99dbff836aed50",
"git.txt": "59fa514dbcf86e8471cbd36e77d64fa4",
"favicon.png": "2ded3154ec596b12c7ed23f3b475853f",
"icons/Icon-192.png": "f4bfab2e260ae800f4653fcefe7d59d9",
"icons/Icon-maskable-192.png": "f4bfab2e260ae800f4653fcefe7d59d9",
"icons/Icon-maskable-512.png": "4344db33dc6636ad1f74aefbe1a6e479",
"icons/Icon-512.png": "4344db33dc6636ad1f74aefbe1a6e479",
"pwa/index.html": "93b25e71fbb594ec4d54ffef82747318",
"pwa/style.css": "adc8ebdd00f62d9234726579d13cd4d9",
"pwa/manifest.json": "c5f582736a39b3926694ac5a22cb56c7",
"pwa/app.js": "742697158028e0ac7762d6d1d3f0b1e0",
"pwa/sw.js": "56b95fff5afb7a27c101abec63aba09e",
"manifest.json": "f5e9b222607e01b9989e148d91e8a3df",
"sitemap.xml": "b150269ad7deadbfa54b255b4afef0a6",
".git/config": "ff93b5abfce2bdf3ca9ec906afc5e758",
".git/objects/0d/6a1572ddd20b68cdacc90b632b085df59d5fb5": "5dab472073c6df063591c3789394c9e0",
".git/objects/92/2fa6327db5bcf13c4e033a5cbae2801a8b334d": "9347e54e4f4802557c74269ee58fb881",
".git/objects/0c/f827e0d89ccc1ee8b5ac2606f380f635456abe": "4879cdb4f0f53fab7ca3d162042cc776",
".git/objects/57/bfb91de34633859f1c7f3388137f608b8a722e": "2cec03d3663184e6d2ad06c46772dd8e",
".git/objects/57/b5e9af01841c1eb41403f5aba818ced8962c11": "8c0d57c018db3c5177dab7ff9c0d4c2a",
".git/objects/03/96cb24b19194328f9a35af8bd5070d96b2a0f6": "1384ee426dc74442d366c864fb4115eb",
".git/objects/9b/d3accc7e6a1485f4b1ddfbeeaae04e67e121d8": "dc1d3b6ac68817e26c52a2b7aca98a10",
".git/objects/9e/5303568f46f8af312d9d33f4e91e038ed6d74b": "ef238bcbb6866668bb4c64cb4da318de",
".git/objects/6a/283ef796284816efa025a8da9aa4ce615c1529": "4aa5759bb198d7045c6a855e6c4c7949",
".git/objects/32/f2862fcb43541eeea120688c77e602c9e40f51": "f754068b9a9db699cc95aca0ea6cd0af",
".git/objects/0b/87d01fd665311eef6c9de19234df7feb85162d": "7856bd34436f0255a606e31fde18a115",
".git/objects/9c/1464a8b49c6bdb3b6f10d606b7768f175945b9": "bf9387e7705ddb4ac426ee3e0cbb5d95",
".git/objects/9c/6bb7a60992b43107b2c783f86ebadad29d1532": "bdd0b44440c0fed9df844b8fc2b5631a",
".git/objects/b5/b48454b45ff718f4bcee0bc158c73175978f87": "827568e9644d2398afbaa023663c7d03",
".git/objects/ac/5e333159865c2686f6d6644fea5ab93532b2c1": "89eccf711af83590638d4a0401574eec",
".git/objects/d7/7cfefdbe249b8bf90ce8244ed8fc1732fe8f73": "1a4ee0c85a695a5f8ce1f75dac7efc0c",
".git/objects/d8/6a3f06a967c25931fdc77029617424a3516161": "15036f41b74fef32149c14296a83edd6",
".git/objects/ab/1f68aa047f42391836152fc18b293467ca1380": "39bef754f2763aeedff1df144e8c0231",
".git/objects/e5/1d6d0bf186bff2549187e2939c36cff881227d": "f1391598eb10b2691d9117008ff9da7e",
".git/objects/eb/568e24dafd255d63612b98d515b2992716132e": "5b36ca8d8552f32b1ea9db223f93d2cd",
".git/objects/c0/150f5c89d8558a9116e9aefa4888108e72a61c": "48f26f0bcfc321398c3b1e54f2be6769",
".git/objects/ee/0e319c5539dbb17d9167d3b7194b5e1a963b42": "ab44c9734516beeebec6230aeae5d2ce",
".git/objects/c9/9b4b657f0b4e8f1598b20466e0edb234b5eb11": "0e7ce63a99858f1e5698eaff5f752fbb",
".git/objects/fd/01257529523a54751d738a0ff4e884197bb723": "5f75f80cd6517c2eac87e3e5df3b0a98",
".git/objects/f2/04823a42f2d890f945f70d88b8e2d921c6ae26": "aa30b45014e5ab878c26ecce9ea89743",
".git/objects/f5/72b90ef57ee79b82dd846c6871359a7cb10404": "fb2ee964a7fc17b8cba79171cb799fa3",
".git/objects/e3/ca31d5fbeb2a1dc92a80fc9b0c2879e7045159": "d7b1eff99952519de1cc8c6beb2d1dbc",
".git/objects/cf/39f195630387890e6aa488998dd87971dd94e7": "bf11a6df497dab48ae055a567231fdd6",
".git/objects/cf/d742de7cb5f3b3edb54537f30e50a7ca7ecd12": "d79c5f6b13738d62ff8d2d1106cb6f14",
".git/objects/fe/5441a21917b1071c4680614611022f9ad80342": "3e0aae1e52993a4077df219be27a590e",
".git/objects/c8/a5164fa264554adc092a87651ed39439848ee1": "ae169f697ef7a7ad19cf810dd68430a4",
".git/objects/c8/08fb85f7e1f0bf2055866aed144791a1409207": "0c4bbf647e92f25144f535178c7f7f15",
".git/objects/c1/c48984a963dc7fe6c7f2eaaec2849f59a0f8d7": "9da393866f8eaab2c496819763e2ede5",
".git/objects/11/db45bd329a131e97a1aaa5b2fedf0d795cbb2f": "3e99d32154918f4bcd0a04c2e1f41614",
".git/objects/73/c63bcf89a317ff882ba74ecb132b01c374a66f": "e14aa589bb7e68e3a524c297a802bde9",
".git/objects/73/2139c898cc22ec2f8ff0472002b8f4f440f528": "16cf8688dce768ed7b09df932918d387",
".git/objects/1a/d7683b343914430a62157ebf451b9b2aa95cac": "dee38288e294701bf8f665ae546a43e3",
".git/objects/19/b1168d66d5a9ec47e3dee4c091afd017854ae4": "6e67b5b9c6c6e9c1741bb959d919f0ab",
".git/objects/75/2bc59f8352ae99cb457cf8a38621902f349dd7": "3c1297e3f18ed00d87d690fc7176db6e",
".git/objects/2a/228ffa54ae83669441df6485698a28889ee715": "53cd9a248f0d26e54a0826b9eea07f3f",
".git/objects/2f/db55322156c6e3b9d2b0f8e9f6dccc47643c7b": "83a563eb55be9e85ff601bc86bf83d25",
".git/objects/6b/90ff85f70e664ea6e64134fae9e99d0cd33367": "b380f31b3e0f161fb4a3ab39e44cec18",
".git/objects/6b/0e13c0853dccbf7517e866de38199e924e399e": "1bfa7c1e4d0d92fd4753d4edbaf15638",
".git/objects/6b/9862a1351012dc0f337c9ee5067ed3dbfbb439": "9524d053d0586a5f9416552b0602a196",
".git/objects/9a/8ef00473065c483a652b8c3d3c00fefda05a36": "37da1c229ba6b211df916f9ce407aa29",
".git/objects/5c/f797de50451b5071d1dd8e4cd8333251eff199": "61b4f96da3f5214a6a4a39466131ccea",
".git/objects/09/2fa2d5d340f71117fb7a4c4d40bb7e44050038": "4aff27eb898c0d4397105f24bfe25aa5",
".git/objects/09/0b9164ea76285a0d0355ef9ae60bd3b15e9a6a": "7b2149d4eabaeba383830af38dda1b18",
".git/objects/5d/14c97c10351cbef2ceb952f85220599d4e2b0f": "54348d747ebc90d2a09e1f85c6fcc27f",
".git/objects/31/b41adfdd3f3ff238cf15d414891449d0006083": "f5add63f150284e2207e6a648467df03",
".git/objects/91/f0d4390adab9e178435b76ef90dad22404df9b": "346cbd52ce7bf0eac61403d1dfcfef7b",
".git/objects/3a/39950981f75fa7f639305ddb58b6e976e0b99e": "2b03c47583558010a1e2035dbbec05a1",
".git/objects/53/18a6956a86af56edbf5d2c8fdd654bcc943e88": "23e8f7ce2c2856c1943e6cb51334416e",
".git/objects/53/3d2508cc1abb665366c7c8368963561d8c24e0": "6d57e2d4816384a5236f4a52d9f1014b",
".git/objects/3f/bad0f6573490be25ffe23825dc62aad8957e35": "f2621ba3b20dfd9b9cb70e27552f195f",
".git/objects/37/a8813ccf9bf32caf3e7a33d1b14c6acb84e4a0": "55e222c1da9517f754a9648fd8cf032f",
".git/objects/52/4c56e96f96cf397afb47a76fd21924521fe801": "ad7e522596e1bbfd13863fdd05cb3814",
".git/objects/64/47adced74bcb28d8673dea87e7d3e7f40cf75d": "ac08fb7baaef58812d7493c2b3ad5519",
".git/objects/d4/3532a2348cc9c26053ddb5802f0e5d4b8abc05": "9dbf5b01e391c548c8343be8d1d4b04e",
".git/objects/a7/8ab5ba21ac730eae01a5e25b9a5bf8ae7e342f": "d1ee4cd94915bf10cdb901401a5584a7",
".git/objects/a7/35e5fef0b8c7c35bed84f4adbab36e3c00a6ab": "a80bcc4bb4c125bda3da82e6bfb1a92d",
".git/objects/dc/11fdb45a686de35a7f8c24f3ac5f134761b8a9": "6a4baf0ee5d7f24d01892e880c87e9b5",
".git/objects/af/fd3b3efdad55aa06e7a3802018a35f00289f4b": "03b131a02b27f28a2401b9f5163fb1ae",
".git/objects/b9/6a5236065a6c0fb7193cb2bb2f538b2d7b4788": "a488dd5b768f3e95bb3ded676201c413",
".git/objects/c3/4478a12fe7f8e8947fa20aac43b562c3495ee7": "faa08c49925dc3c7d2de1f4de4345ad7",
".git/objects/ea/c939f5225b526d394ae622b0471b916ea6064f": "9195ade5f437ce896b8d2e49c843dd83",
".git/objects/cd/59b7766691c97b6979ac383017bd964010e8a5": "78ff68bfe55bd234ed4ed07dc705ff7d",
".git/objects/f0/03a22f04c1328a188be5a668a1f421b3c2e48b": "33a9c3ba7532974a0b24858c5c943a5a",
".git/objects/fa/198993501c55944efdc1615716fbf8c29c8bfc": "a3afe642d7ce9066b34db2e50bafb7b5",
".git/objects/e9/94225c71c957162e2dcc06abe8295e482f93a2": "c3694958e54483a81b3e32ab9f84ece2",
".git/objects/f1/ff534471b1109b6be9239ae994c5e34c6f7ada": "892be1ca7b441fc7546754cd8bd42e3c",
".git/objects/e7/3daa251048e845ecf958ca68410c34b3b9da77": "08de7624ab2f35b978ff3864a0c173a5",
".git/objects/e0/8b6425b50f7f00240def5708863e9ae114211e": "5042137ea10e8f3a952ea82dd6260dde",
".git/objects/e0/7ac7b837115a3d31ed52874a73bd277791e6bf": "eaf69ee68e07ccd33759fba4b5e36d4e",
".git/objects/46/4ab5882a2234c39b1a4dbad5feba0954478155": "0bb82caa96c962530864f28e847f4ab9",
".git/objects/79/25291ea9516570c668d94b56c4a741d165e234": "a2bd5489d9ca53434a57b5639d35aed0",
".git/objects/77/1a0a2cc69ed779acbea122deb920cdf753c98b": "6147c9dd5876e3d0de473359f736d172",
".git/objects/48/5b591de40641e2aa1f2d010d497e9d0d10fbfa": "807302fc3badf2c57edafc2df5a397d4",
".git/objects/70/a234a3df0f8c93b4c4742536b997bf04980585": "6dc767ec6498faa598b6dd7d00386498",
".git/objects/70/a3b3cfcb1bbcce1fa85a38a9332b6e6e371706": "20f626d45eb3c9e3f81b2b860aa28f84",
".git/objects/4a/18ee5b12d700d4a67a92722d80496fc604f028": "872b66141ae154aa9556999a0207d0d1",
".git/objects/24/adaa5a0d4e144128dae15c64fbae67e37acf8c": "d4fadd452d2e52901bbce601529c3b58",
".git/objects/8d/f52bffe290693a873280bf763d075bf7802971": "a735390a2b21d8c3c039b390f00d853e",
".git/objects/71/145ed07c381977cdd84bbe02232258607bb4fc": "21fb6f5f942022321726f986e57176d2",
".git/objects/47/8264300e03c4a7c74cf85b5f81095f308da75d": "d1985d7d22645ff95c9f713aeeeca74f",
".git/HEAD": "cf7dd3ce51958c5f13fece957cc417fb",
".git/info/exclude": "036208b4a1ab4a235d75c181e685e5a3",
".git/logs/HEAD": "6089d3b0f63c3a69c1f331c332979c30",
".git/logs/refs/heads/main": "624e87641fd1f8a0c4c9b5b75d7e131a",
".git/logs/refs/remotes/origin/main": "ff33a72b8740c0ebccef5724fb9acca9",
".git/description": "a0a7c3fff21f2aea3cfa1d0316dd816c",
".git/hooks/commit-msg.sample": "579a3c1e12a1e74a98169175fb913012",
".git/hooks/pre-rebase.sample": "56e45f2bcbc8226d2b4200f7c46371bf",
".git/hooks/sendemail-validate.sample": "4d67df3a8d5c98cb8565c07e42be0b04",
".git/hooks/pre-commit.sample": "5029bfab85b1c39281aa9697379ea444",
".git/hooks/applypatch-msg.sample": "ce562e08d8098926a3862fc6e7905199",
".git/hooks/fsmonitor-watchman.sample": "a0b2633a2c8e97501610bd3f73da66fc",
".git/hooks/pre-receive.sample": "2ad18ec82c20af7b5926ed9cea6aeedd",
".git/hooks/prepare-commit-msg.sample": "2b5c047bdb474555e1787db32b2d2fc5",
".git/hooks/post-update.sample": "2b7ea5cee3c49ff53d41e00785eb974c",
".git/hooks/pre-merge-commit.sample": "39cb268e2a85d436b9eb6f47614c3cbc",
".git/hooks/pre-applypatch.sample": "054f9ffb8bfe04a599751cc757226dda",
".git/hooks/pre-push.sample": "2c642152299a94e05ea26eae11993b13",
".git/hooks/update.sample": "647ae13c682f7827c22f5fc08a03674e",
".git/hooks/push-to-checkout.sample": "c7ab00c7784efeadad3ae9b228d4b4db",
".git/refs/heads/main": "1ab95db360cba5c55af93937c6009bd9",
".git/refs/remotes/origin/main": "1ab95db360cba5c55af93937c6009bd9",
".git/gk/config": "003275e68d22bfbb38d8a0eea51b171d",
".git/index": "b4ee6e43621678f145b7de9370fc1539",
".git/COMMIT_EDITMSG": "8bf3a20948de76ae9a7f2129d0ec5fe4",
".git/FETCH_HEAD": "971522c7e98d714fc4a64b7be9b1b239",
"assets/AssetManifest.json": "513e0f1a4aaedca83d2f33b97094bae8",
"assets/NOTICES": "cef51184950d4e1e7e4ed8cc8b1585a6",
"assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/AssetManifest.bin.json": "df168dc34789abce79ef24f2387c7aa7",
"assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/AssetManifest.bin": "8565e75c8497d1ece3e7d67990845855",
"assets/fonts/MaterialIcons-Regular.otf": "951f883b4e82b43b8cc8b2b07bc9f471",
"assets/assets/env.txt": "08f5f58f29ea3887cd655d00cbc2a7b5",
"assets/assets/images/Icon-512.png": "4344db33dc6636ad1f74aefbe1a6e479",
"assets/assets/web/flutter_bootstrap.js": "5a7468d952a2c8ec6ab2cb29a02c74a8",
"assets/assets/web/version.json": "1b9113546028f5eff5f73b56c8a3c82d",
"assets/assets/web/index.html": "19432020073347df1417b66fcb7588ca",
"assets/assets/web/main.dart.js": "3c3241933c08d5be5f1a589c6ff2f595",
"assets/assets/web/flutter.js": "83d881c1dbb6d6bcd6b42e274605b69c",
"assets/assets/web/favicon.png": "2ded3154ec596b12c7ed23f3b475853f",
"assets/assets/web/icons/Icon-192.png": "f4bfab2e260ae800f4653fcefe7d59d9",
"assets/assets/web/icons/Icon-maskable-192.png": "f4bfab2e260ae800f4653fcefe7d59d9",
"assets/assets/web/icons/Icon-maskable-512.png": "4344db33dc6636ad1f74aefbe1a6e479",
"assets/assets/web/icons/Icon-512.png": "4344db33dc6636ad1f74aefbe1a6e479",
"assets/assets/web/pwa/index.html": "93b25e71fbb594ec4d54ffef82747318",
"assets/assets/web/pwa/style.css": "adc8ebdd00f62d9234726579d13cd4d9",
"assets/assets/web/pwa/manifest.json": "c5f582736a39b3926694ac5a22cb56c7",
"assets/assets/web/pwa/app.js": "742697158028e0ac7762d6d1d3f0b1e0",
"assets/assets/web/pwa/sw.js": "56b95fff5afb7a27c101abec63aba09e",
"assets/assets/web/manifest.json": "f5e9b222607e01b9989e148d91e8a3df",
"assets/assets/web/assets/AssetManifest.json": "753108c073c081b1f7ffb4687402532e",
"assets/assets/web/assets/NOTICES": "cef51184950d4e1e7e4ed8cc8b1585a6",
"assets/assets/web/assets/FontManifest.json": "dc3d03800ccca4601324923c0b1d6d57",
"assets/assets/web/assets/AssetManifest.bin.json": "91fc4122170955e7d9ee5c1cea03e297",
"assets/assets/web/assets/packages/cupertino_icons/assets/CupertinoIcons.ttf": "33b7d9392238c04c131b6ce224e13711",
"assets/assets/web/assets/shaders/ink_sparkle.frag": "ecc85a2e95f5e9f53123dcaf8cb9b6ce",
"assets/assets/web/assets/AssetManifest.bin": "26c7391fe2569367c9701d31f42c6a20",
"assets/assets/web/assets/fonts/MaterialIcons-Regular.otf": "a8c3d3af90b9aabe57868af1a29a1629",
"assets/assets/web/assets/assets/env.txt": "08f5f58f29ea3887cd655d00cbc2a7b5",
"assets/assets/web/assets/assets/images/Icon-512.png": "4344db33dc6636ad1f74aefbe1a6e479",
"assets/assets/web/canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"assets/assets/web/canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"assets/assets/web/canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"assets/assets/web/canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"assets/assets/web/canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"assets/assets/web/canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93",
"robot.txt": "9105c84c037ac345c166e442329d7b75",
"canvaskit/skwasm.js": "ea559890a088fe28b4ddf70e17e60052",
"canvaskit/skwasm.js.symbols": "e72c79950c8a8483d826a7f0560573a1",
"canvaskit/canvaskit.js.symbols": "bdcd3835edf8586b6d6edfce8749fb77",
"canvaskit/skwasm.wasm": "39dd80367a4e71582d234948adc521c0",
"canvaskit/chromium/canvaskit.js.symbols": "b61b5f4673c9698029fa0a746a9ad581",
"canvaskit/chromium/canvaskit.js": "8191e843020c832c9cf8852a4b909d4c",
"canvaskit/chromium/canvaskit.wasm": "f504de372e31c8031018a9ec0a9ef5f0",
"canvaskit/canvaskit.js": "728b2d477d9b8c14593d4f9b82b484f3",
"canvaskit/canvaskit.wasm": "7a3f4ae7d65fc1de6a6e7ddd3224bc93"};
// The application shell files that are downloaded before a service worker can
// start.
const CORE = ["main.dart.js",
"index.html",
"flutter_bootstrap.js",
"assets/AssetManifest.bin.json",
"assets/FontManifest.json"];

// During install, the TEMP cache is populated with the application shell files.
self.addEventListener("install", (event) => {
  self.skipWaiting();
  return event.waitUntil(
    caches.open(TEMP).then((cache) => {
      return cache.addAll(
        CORE.map((value) => new Request(value, {'cache': 'reload'})));
    })
  );
});
// During activate, the cache is populated with the temp files downloaded in
// install. If this service worker is upgrading from one with a saved
// MANIFEST, then use this to retain unchanged resource files.
self.addEventListener("activate", function(event) {
  return event.waitUntil(async function() {
    try {
      var contentCache = await caches.open(CACHE_NAME);
      var tempCache = await caches.open(TEMP);
      var manifestCache = await caches.open(MANIFEST);
      var manifest = await manifestCache.match('manifest');
      // When there is no prior manifest, clear the entire cache.
      if (!manifest) {
        await caches.delete(CACHE_NAME);
        contentCache = await caches.open(CACHE_NAME);
        for (var request of await tempCache.keys()) {
          var response = await tempCache.match(request);
          await contentCache.put(request, response);
        }
        await caches.delete(TEMP);
        // Save the manifest to make future upgrades efficient.
        await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
        // Claim client to enable caching on first launch
        self.clients.claim();
        return;
      }
      var oldManifest = await manifest.json();
      var origin = self.location.origin;
      for (var request of await contentCache.keys()) {
        var key = request.url.substring(origin.length + 1);
        if (key == "") {
          key = "/";
        }
        // If a resource from the old manifest is not in the new cache, or if
        // the MD5 sum has changed, delete it. Otherwise the resource is left
        // in the cache and can be reused by the new service worker.
        if (!RESOURCES[key] || RESOURCES[key] != oldManifest[key]) {
          await contentCache.delete(request);
        }
      }
      // Populate the cache with the app shell TEMP files, potentially overwriting
      // cache files preserved above.
      for (var request of await tempCache.keys()) {
        var response = await tempCache.match(request);
        await contentCache.put(request, response);
      }
      await caches.delete(TEMP);
      // Save the manifest to make future upgrades efficient.
      await manifestCache.put('manifest', new Response(JSON.stringify(RESOURCES)));
      // Claim client to enable caching on first launch
      self.clients.claim();
      return;
    } catch (err) {
      // On an unhandled exception the state of the cache cannot be guaranteed.
      console.error('Failed to upgrade service worker: ' + err);
      await caches.delete(CACHE_NAME);
      await caches.delete(TEMP);
      await caches.delete(MANIFEST);
    }
  }());
});
// The fetch handler redirects requests for RESOURCE files to the service
// worker cache.
self.addEventListener("fetch", (event) => {
  if (event.request.method !== 'GET') {
    return;
  }
  var origin = self.location.origin;
  var key = event.request.url.substring(origin.length + 1);
  // Redirect URLs to the index.html
  if (key.indexOf('?v=') != -1) {
    key = key.split('?v=')[0];
  }
  if (event.request.url == origin || event.request.url.startsWith(origin + '/#') || key == '') {
    key = '/';
  }
  // If the URL is not the RESOURCE list then return to signal that the
  // browser should take over.
  if (!RESOURCES[key]) {
    return;
  }
  // If the URL is the index.html, perform an online-first request.
  if (key == '/') {
    return onlineFirst(event);
  }
  event.respondWith(caches.open(CACHE_NAME)
    .then((cache) =>  {
      return cache.match(event.request).then((response) => {
        // Either respond with the cached resource, or perform a fetch and
        // lazily populate the cache only if the resource was successfully fetched.
        return response || fetch(event.request).then((response) => {
          if (response && Boolean(response.ok)) {
            cache.put(event.request, response.clone());
          }
          return response;
        });
      })
    })
  );
});
self.addEventListener('message', (event) => {
  // SkipWaiting can be used to immediately activate a waiting service worker.
  // This will also require a page refresh triggered by the main worker.
  if (event.data === 'skipWaiting') {
    self.skipWaiting();
    return;
  }
  if (event.data === 'downloadOffline') {
    downloadOffline();
    return;
  }
});
// Download offline will check the RESOURCES for all files not in the cache
// and populate them.
async function downloadOffline() {
  var resources = [];
  var contentCache = await caches.open(CACHE_NAME);
  var currentContent = {};
  for (var request of await contentCache.keys()) {
    var key = request.url.substring(origin.length + 1);
    if (key == "") {
      key = "/";
    }
    currentContent[key] = true;
  }
  for (var resourceKey of Object.keys(RESOURCES)) {
    if (!currentContent[resourceKey]) {
      resources.push(resourceKey);
    }
  }
  return contentCache.addAll(resources);
}
// Attempt to download the resource online before falling back to
// the offline cache.
function onlineFirst(event) {
  return event.respondWith(
    fetch(event.request).then((response) => {
      return caches.open(CACHE_NAME).then((cache) => {
        cache.put(event.request, response.clone());
        return response;
      });
    }).catch((error) => {
      return caches.open(CACHE_NAME).then((cache) => {
        return cache.match(event.request).then((response) => {
          if (response != null) {
            return response;
          }
          throw error;
        });
      });
    })
  );
}
