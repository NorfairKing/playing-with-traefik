{ nixosTest
, python3
}:
nixosTest ({ lib, pkgs, ... }: {
  name = "traifik-idea-test";
  nodes = {
    jeff = {
      networking.firewall.allowedTCPPorts = [
        80
      ];
      services.traefik = {
        enable = true;

        staticConfigOptions = {
          global = {
            checkNewVersion = false;
            sendAnonymousUsage = false;
          };

          log.level = "DEBUG";
          entryPoints = {
            web = {
              address = ":80";
            };
          };
        };

        dynamicConfigOptions = {
          http = {
            services = {
              simple.loadBalancer.servers = [{ url = "http://jared:8000"; }];
            };
            routers = {
              route_simple = {
                entryPoints = [ "web" ];
                rule = "Host(`jared`)";
                service = "simple";
              };
            };
          };
        };
      };
    };
    jared = {
      networking.firewall.allowedTCPPorts = [
        8000
      ];
      systemd.services.simplehttp = {
        script = "${python3}/bin/python -m http.server 8000";
        serviceConfig.Type = "simple";
        wantedBy = [ "multi-user.target" ];
      };
    };
    client = { };
  };
  testScript = ''
    jeff.start()
    jared.start()
    client.start()

    jeff.wait_for_unit("multi-user.target")
    jared.wait_for_unit("multi-user.target")
    client.wait_for_unit("multi-user.target")

    jeff.require_unit_state("traefik.service")
    jared.require_unit_state("simplehttp.service")

    client.succeed("curl http://jared:8000")
    client.succeed("curl -H 'Host: jared' http://jeff")
  '';
})
