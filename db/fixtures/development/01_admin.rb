User.seed(:id, [
  {
    id: 1,
    name: "Administrator",
    email: "admin@local.host",
    username: 'root',
    password: "5iveL!fe",
    password_confirmation: "5iveL!fe",
    admin: true,
  },
  {
    id: 2,
    name: "Andrey",
    email: "me@zzet.org",
    username: 'zzet',
    password: "123456",
    password_confirmation: "123456",
    admin: true,
  },
  {
    id: 3,
    name: "Administrator",
    email: "admin@undev.host",
    username: 'undev',
    password: "123456",
    password_confirmation: "123456",
    admin: true,
  }
])
