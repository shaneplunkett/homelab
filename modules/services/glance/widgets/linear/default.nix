{ secrets }:
{
  type = "custom-api";
  title = "Linear";
  title-url = "https://linear.app/metrokitten/my-issues/assigned";
  cache = "5m";
  url = "https://api.linear.app/graphql";
  method = "POST";
  headers.Authorization._secret = secrets.linear-api-key.path;
  body-type = "json";
  body.query = builtins.readFile ./query.graphql;
  template = builtins.readFile ./template.html;
}
