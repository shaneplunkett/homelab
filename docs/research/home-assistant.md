# Home Assistant for the house

The plan for running every smart thing in the apartment from Home Assistant,
locally, so an internet drop-out or a sulking hub can't hold the lights
hostage. A research agent did the first pass, then Shane and Vex went through
it and changed a fair bit. Claims cite the sources list at the bottom, and
anything unconfirmed says so.

## Decisions

- **Home Assistant runs from the official container image** in its own pve
  container. Zigbee2MQTT and Mosquitto run next to it as native NixOS
  services.
- **The SLZB-06p7 is the Zigbee coordinator,** reached over the network.
- **Apple Home is out.** No HomeKit Bridge. Siri isn't used, and the Home
  Assistant app replaces the Home app.
- **Hue bulbs move to Zigbee** and the Hue bridge retires.
- **Sign-in is hass-oidc-auth with Pocket ID.** The route is `home`, and Shane
  is the only user.
- **Away from home is Tailscale.** No Nabu Casa, no Cloudflare Access.

## 1. How it runs

**The official container image,** through `oci-containers` like openGym,
plus `services.zigbee2mqtt` and `services.mosquitto`.

Why not the NixOS `services.home-assistant` module:

- Home Assistant deprecated the Core install type, which is what the module
  runs, and stopped taking its issues [2].
- nixpkgs builds Home Assistant without pip [3], so every integration's
  dependencies have to be in the package first [4]. Adding a new brand of
  gadget becomes a PR and a deploy.
- HACS can't work without pip. That rules out the Dyson integration and
  community extras.
- Most of Home Assistant's config lives in its UI and its own storage anyway,
  so Nix wouldn't be describing much of it.

The container image is a supported install type [1], HACS works, and Renovate
bumps the tag. Nix still owns the container, backups, monitoring and route.

Why not a Home Assistant OS VM: it's a pet machine outside Nix. Its pull is
USB passthrough for Zigbee and Thread, and the SLZB is a network coordinator,
so that doesn't apply.

### Backups

- Back up the Home Assistant config volume, the Zigbee2MQTT state and the
  Mosquitto state. The Zigbee2MQTT state holds the network key, and losing it
  means re-pairing every Zigbee device.
- The recorder database is SQLite, so copy it with `.backup` in the `prepare`
  step and exclude the live file, like FreshRSS.
- The built-in Backup integration works on the container install too [35].

## 2. Networking

**Home Assistant on the main network, with one UniFi policy into the IoT
zone.** The mDNS proxy already reflects discovery across.

- Add a zone policy from the Home Assistant host to the IoT zone, action
  Allow, with "Auto Allow Return Traffic" ticked [33].
- Check the mDNS proxy covers both networks [34].
- Give every IoT gadget a DHCP reservation, so Home Assistant can still find
  it if mDNS gets flaky.
- Put the SLZB on the IoT network. Its switch port is PoE, so the port's
  network setting is all it needs.
- Open 8123 for the ingress in the container's firewall.

No second network card on the IoT VLAN. It only matters for Matter, and
nothing needs Matter yet.

## 3. Devices

| Device | Integration | Local? | After a power cut |
|---|---|---|---|
| Hue bulbs | Zigbee2MQTT | Yes | Off |
| Hue Play bars | Zigbee2MQTT | Yes | As they were |
| Zemismart blinds (ZM85EL-1Z) | Zigbee2MQTT | Yes | n/a, battery |
| 2× LIFX Switch | HomeKit Controller | Yes | App setting or automation |
| 3× Meross MSL320 strip | HomeKit Controller | Yes | App setting or automation |
| 2× Meross MSS210 plug | HomeKit Controller | Yes | Off, by automation |
| Sensibo | HomeKit Controller, cloud if needed | Mostly | n/a |
| Dyson fan | `ha-dyson` from HACS | Yes, after one login | n/a |
| Eve Aqua | HomeKit Controller over Thread | Yes | n/a |

"HomeKit Controller" is Home Assistant speaking the HomeKit protocol to a
device directly. It has nothing to do with Apple Home, except that a device
has to leave Apple Home before Home Assistant can pair it [8][9].

### Hue

- Every bulb, the Play bars included, joins Zigbee2MQTT directly. The bridge
  retires when the last one's moved.
- Zigbee2MQTT exposes `power_on_behavior` on Hue lights [6], so plain off
  after a power cut works without an automation.
- Move bulbs one at a time. Both networks run side by side until the end.
- Deleting a bulb in the Hue app usually resets it. Otherwise use Zigbee2MQTT's
  touchlink reset with the bulb near the SLZB.
- **Starlight** is a static scene. Before moving the Play bars, connect Home
  Assistant to the Hue bridge [7], put Starlight on, and save it as a Home
  Assistant scene. It copies the exact colours, and the scene keeps working
  after the bars move.
- The mains-powered bulbs become Zigbee routers, which the battery blinds need.

### Zemismart blinds

- Zigbee2MQTT supports the ZM85EL-1Z as a rebadged Tuya `TS0601_cover_1` [5].
- Pairing: press the set button three times within five seconds until the LED
  flashes blue [5].
- They're battery devices, so they don't route and need a strong link. Pair
  them near the SLZB first, then move them. If they drop off in place, a
  mains-powered Zigbee device near the windows fixes it.
- The first attempt failed on a cheap USB stick. The SLZB is a much stronger
  radio.

### LIFX switches

They switch dumb loads: the living area ceiling lights, and the bathroom fan
and light.

- Home Assistant's `lifx` integration doesn't support the Switch [10], so it's
  HomeKit Controller.
- The Switch only advertises HomeKit for 15 minutes after a reboot [10].
  Reboot it in the LIFX app, then pair straight away. The missed window is
  probably why pairing failed before.
- The HomeKit code comes from "Get Code" in the LIFX app [11].
- Don't take the Matter firmware update. It's one-way and kills the HomeKit
  code [12].
- LIFX only documents power restore for lights [13]. Check the Switch's
  settings in the app.
- If they're still cursed, swap them for Zigbee switches.

### Meross strips and plugs

- The codes are on the strips' inline controller boxes and on the plugs.
  Shane also has photos of them. Get the codes before removing anything from
  Apple Home, because the code is the only way back in.
- The plugs run the 3D printer and the coffee machine. Both stay off after a
  power cut.
- Meross only says devices "retain their settings" [14]. Check the Meross app
  for a power-on setting before unpairing.
- Fallback for a lost code: `meross_lan` from HACS [15]. It needs the Meross
  login once for each device's key, and it polls instead of pushing.

### Sensibo

- The Home app can't switch heat/cool or move the flap. That's probably what
  Sensibo exposes over HomeKit, so HomeKit Controller may have the same gap.
  UNCONFIRMED until it's paired.
- Pair it locally first. If mode or swing is missing, add the Sensibo cloud
  integration [16] alongside it for those.
- Low stakes: the Sensibo is an IR remote, so the air con's own remote always
  works.

### Dyson

- Home Assistant has no built-in Dyson support anymore. `ha-dyson` [17]
  replaces the old community integrations and controls the fan locally.
- It needs the Dyson login once to fetch the fan's local credentials.

### Eve Aqua

- It's a Thread device. Home Assistant can pair HomeKit Thread devices through
  an Apple border router: remove it from Apple Home without resetting it, then
  pair [8].
- Home Assistant needs to be on the same network as a border router [8]. The
  main network already gets a route to the Thread network from the Bathroom
  HomePod, so the plan above works.
- The HomePod and Apple TVs stay on as Thread border routers [23]. That's
  local, and it's only this one gadget.
- The SLZB's chip can run Thread, but only one firmware at a time, and it
  stays on Zigbee. Home Assistant gave up on running both at once. UNCONFIRMED
  from a primary source.

## 4. After a power cut

- Set off-after-power-cut on the device wherever it has a setting: Hue through
  Zigbee2MQTT [6], Shelly in its web UI [21][22].
- One automation covers the rest. Trigger on Home Assistant starting [24], and
  on any light or plug going from `unavailable` to `on`, then turn it off. The
  Play bars are excluded.
- Lights without a setting will still flash on for a few seconds before Home
  Assistant catches them.

## 5. Sign-in

- Home Assistant has no OIDC login of its own [25]. hass-oidc-auth adds one
  and has a Pocket ID guide [26][27]. The callback is
  `https://home.shaneplunkett.com/auth/oidc/callback` [27].
- Install it from HACS.
- The iPhone app finishes login in Safari with a device code, so the passkey
  works [28].
- Keep Home Assistant out of the oauth2-proxy gate. The plugin's FAQ says to
  drop proxy-level login [28], and the iPhone app can't get through one
  [29][30].
- Pocket ID client: confidential, PKCE, Skip Consent, Client ID `home`. The
  secret goes in Bitwarden and agenix as `docs/pve/auth.md` describes. Shane
  makes it in the Pocket ID UI.
- Keep a local admin login in Bitwarden for when Pocket ID is down. Pocket ID
  is only used at login, so existing app sessions keep working without it.
- Set "Trust X-Forwarded-For" and the ingress as a trusted proxy in the UI.
  Newer releases manage HTTP settings there rather than in YAML [31].

## 6. Away from home

- Tailscale, which every host already runs. One URL everywhere:
  `https://home.shaneplunkett.com`.
- Nabu Casa is a paid relay through their servers [32]. Not needed.
- Cloudflare Access breaks the iPhone app [29].
- **Test it with the internet unplugged.** Every link from phone to bulb is
  local, but Tailscale on the phone can get odd about DNS with no internet.
  Turn a light off from the app with the WAN pulled, and fix anything that
  breaks.

## Migration plan

Each step leaves the house working. **Shane** marks steps that need her hands.

### 1. Stand it up

1. PR: Terraform container, host module, hive node, the Home Assistant
   container, Zigbee2MQTT, Mosquitto, backups and the `home` route.
2. **Shane:** the UniFi zone policy, the mDNS proxy check and DHCP reservations.
3. **Shane:** make the Pocket ID client. A PR wires the secret in. Done when her
   passkey gets her in on the web and on her phone.

### 2. Easy wins, nothing unpaired

4. **Shane:** connect the Hue bridge, then save Starlight as a scene.
5. Add the Dyson through HACS.
6. Add the after-a-power-cut automation.

### 3. Zigbee

7. **Shane:** plug the SLZB in on the IoT network and check it's running
   Zigbee coordinator firmware.
8. Move one Hue bulb as a trial and set its power-on behaviour.
9. Move the rest of the Hue bulbs, then the Play bars, then retire the bridge.
10. Pair the blinds.

### 4. Out of Apple Home, one at a time

11. **Shane:** one Meross plug as the trial. Code first, check the app for a
    power-on setting, remove it from Apple Home, pair it in Home Assistant.
12. The other plug and the three strips.
13. The LIFX switches, using the reboot-then-pair trick.
14. The Sensibo, then the Eve Aqua.

### 5. The test

15. **Shane:** unplug the internet and turn a light off from the app.

## Later

- **SwitchBot lock.** The built-in SwitchBot Bluetooth integration controls it
  locally with no hub, after one SwitchBot login for its encryption key [18].
  It needs an ESPHome Bluetooth proxy near the door. pve's own Bluetooth can't
  be used: the kernel only allows Bluetooth sockets in the host's network
  namespace [19], and containers get their own. The keypad keeps talking to
  the lock directly. Decide which automations may unlock rather than lock.
- **Bedside Zigbee remote,** bound directly to the bedroom bulbs so it works
  even with Home Assistant down.
- **The two Shellys** on the balcony and bathroom lights. Check they still
  work first. The core `shelly` integration covers them [20]. They may be
  running HomeKit firmware from years ago.
- **Bathroom fan on humidity.** Needs a sensor Home Assistant can read. The
  HomePod's sensor isn't reachable [36], so use a cheap Zigbee one.
- **3D printer integration,** and **a Thread border router of our own** so
  Apple drops out entirely.

## Sources

1. Installation methods: https://www.home-assistant.io/installation/
2. Deprecating Core and Supervised: https://www.home-assistant.io/blog/2025/05/22/deprecating-core-and-supervised-installation-methods-and-32-bit-systems
3. nixpkgs package, `skipPip`: https://github.com/NixOS/nixpkgs/blob/master/pkgs/servers/home-assistant/default.nix
4. NixOS module: https://github.com/NixOS/nixpkgs/blob/master/nixos/modules/services/home-automation/home-assistant.nix
5. Zigbee2MQTT, Tuya TS0601_cover_1: https://www.zigbee2mqtt.io/devices/TS0601_cover_1.html
6. Zigbee2MQTT, Hue Play light bar: https://www.zigbee2mqtt.io/devices/915005733701.html
7. Hue integration: https://www.home-assistant.io/integrations/hue/
8. HomeKit Controller integration: https://www.home-assistant.io/integrations/homekit_controller/
9. HomeKit Controller config flow, skips paired accessories: https://github.com/home-assistant/core/blob/dev/homeassistant/components/homekit_controller/config_flow.py
10. LIFX integration, LIFX Switch section: https://www.home-assistant.io/integrations/lifx/
11. LIFX Switch HomeKit pairing, legacy firmware: https://support.lifx.com/hc/en-us/articles/14509316544663-Switch-HomeKit-Pairing-Legacy-Non-Matter-Firmware
12. LIFX Matter firmware updates: https://support.lifx.com/hc/en-us/articles/34857864915095-Matter-Firmware-Updates-for-LIFX-Devices
13. LIFX power restore, lights: https://support.lifx.com/hc/en-us/articles/37787076098071-Light-Restore-What-happens-after-power-changes
14. Meross FAQ, power outage: https://www.meross.com/faq/38.html
15. meross_lan: https://github.com/krahabb/meross_lan
16. Sensibo integration: https://www.home-assistant.io/integrations/sensibo/
17. ha-dyson: https://github.com/libdyson-wg/ha-dyson
18. SwitchBot Bluetooth integration: https://www.home-assistant.io/integrations/switchbot/
19. Linux `af_bluetooth.c`, `init_net` check: https://github.com/torvalds/linux/blob/master/net/bluetooth/af_bluetooth.c
20. Shelly integration: https://www.home-assistant.io/integrations/shelly/
21. Shelly Gen1 API, `default_state`: https://shelly-api-docs.shelly.cloud/gen1/
22. Shelly Gen2 Switch, `initial_state`: https://shelly-api-docs.shelly.cloud/gen2/ComponentsAndServices/Switch
23. Apple, Thread border routers: https://support.apple.com/en-us/102078
24. Home Assistant start trigger: https://www.home-assistant.io/docs/automation/trigger/#home-assistant-trigger
25. Home Assistant auth providers: https://www.home-assistant.io/docs/authentication/providers/
26. hass-oidc-auth: https://github.com/christiaangoossens/hass-oidc-auth
27. hass-oidc-auth Pocket ID guide: https://github.com/christiaangoossens/hass-oidc-auth/blob/main/docs/provider-configurations/pocket-id.md
28. hass-oidc-auth FAQ: https://github.com/christiaangoossens/hass-oidc-auth/blob/main/docs/faq.md
29. iOS app, custom headers not planned: https://github.com/home-assistant/iOS/issues/5305
30. iOS app, use mTLS instead of secondary auth: https://github.com/home-assistant/iOS/issues/5563
31. HTTP integration: https://www.home-assistant.io/integrations/http/
32. Home Assistant Cloud: https://www.home-assistant.io/integrations/cloud/
33. UniFi zone-based firewalls: https://help.ui.com/hc/en-us/articles/115003173168-Zone-Based-Firewalls-in-UniFi
34. UniFi mDNS proxy: https://help.ui.com/hc/en-us/articles/12648701398807-UniFi-Gateway-Multicast-DNS-mDNS-Proxy
35. Backup integration: https://www.home-assistant.io/integrations/backup/
36. Apple TV integration: https://www.home-assistant.io/integrations/apple_tv/
