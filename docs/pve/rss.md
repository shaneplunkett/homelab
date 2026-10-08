# RSS

NixOS LXC on PVE running FreshRSS, the feed reader at
`https://rss.shaneplunkett.com`. The container is `module "rss"` in
`terraform/pve-rss.tf`, and the service is `modules/services/freshrss`, using
the nixpkgs module (nginx and php-fpm, SQLite).

## Signing in

The ingress gates it with oauth2-proxy, so Pocket ID's passkey is the only
login. FreshRSS runs in `http_auth` mode and takes the username from the
`X-User` header the ingress sends, which is the Pocket ID user's `sub` (a
UUID), not their username. The admin is the UUID in `defaultUser`. Anyone else
who gets through the gate is registered as a normal user on their first visit.

The header only counts when the request comes from the ingress host and isn't
under `/api/`, because nginx on the rss host turns it into `REMOTE_USER` for
those requests and nothing else. `/api/` skips the gate so phone apps work, and
the gate doesn't set `X-User` there, so a client could send its own. Keep the
`/api/` exception in the nginx map if you touch it.

## Phone apps

Apps use the Google Reader API (`https://rss.shaneplunkett.com/api/greader.php`)
with the username and a separate API password, which each user sets under
Settings, Profile. Readrops, FeedMe and NetNewsWire all speak it.

## Extensions

The YouTube and Af_Readability extensions are installed from Nix but start
switched off. FreshRSS keeps which extensions are on, and their settings, in
each user's own config, so turn them on under Settings, Extensions:

- **YouTube** plays videos inside the article. Turn on the no-cookie domain
  in its settings.
- **Af_Readability** fetches the full article for feeds that only send a
  summary. Tick the feeds you want in its settings. It only applies to new
  articles, not ones already fetched.

For a site Af_Readability gets wrong, a feed's own "Article CSS selector on
original website" setting does the same job by hand.

## Backups

Each user's `db.sqlite` is copied with SQLite's `.backup` before restic runs,
and the live file is excluded, so a backup never catches it mid-write. To
restore, put `backup.sqlite` back as `db.sqlite` with the service stopped.
