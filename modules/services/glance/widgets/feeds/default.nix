let
  subreddit = name: {
    type = "reddit";
    subreddit = name;
    show-thumbnails = true;
    collapse-after = 6;
  };
in
{
  type = "group";
  widgets = [
    (subreddit "homelab")
    (subreddit "selfhosted")
    (subreddit "NixOS")
    {
      type = "hacker-news";
      collapse-after = 6;
    }
    {
      type = "lobsters";
      collapse-after = 6;
    }
  ];
}
