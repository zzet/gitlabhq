User.seed(:id, [
  {
    id: 1,
    name: "Administrator",
    email: "admin@local.host",
    username: 'root',
    password: "5iveL!fe",
    password_confirmation: "5iveL!fe",
    admin: true,
    projects_limit: 100,
    theme_id: Gitlab::Theme::MARS
  }
])
