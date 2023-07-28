{ nixosTest
, python3
}:
let
  consulIP = "192.168.1.66";
in
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
          providers.consul.endpoints = [ "${consulIP}:8500" ];
        };
      };
    };
    jared = {
      networking.firewall.allowedTCPPorts = [
        8001
        8002
      ];
      systemd.services.simplehttp1 = {
        script = "${python3}/bin/python -m http.server 8001";
        serviceConfig.Type = "simple";
        wantedBy = [ "multi-user.target" ];
      };
      systemd.services.simplehttp2 = {
        script = "${python3}/bin/python -m http.server 8002";
        serviceConfig.Type = "simple";
        wantedBy = [ "multi-user.target" ];
      };
    };
    john = {
      networking.interfaces.eth1.ipv4.addresses = pkgs.lib.mkOverride 0 [
        { address = consulIP; prefixLength = 16; }
      ];
      services.consul = {
        enable = true;
        extraConfig = {
          server = true;
          bootstrap_expect = 1;
          bind_addr = consulIP;
          disable_update_check = true;
        };
      };
      # See https://www.consul.io/docs/install/ports.html
      networking.firewall = {
        allowedTCPPorts = [ 8301 8302 8600 8500 8300 ];
        allowedUDPPorts = [ 8301 8302 8600 ];
      };
    };
    client = { };
  };
  testScript = ''
    jeff.start()
    jared.start()
    john.start()
    client.start()

    jeff.wait_for_unit("multi-user.target")
    jared.wait_for_unit("multi-user.target")
    john.wait_for_unit("multi-user.target")
    client.wait_for_unit("multi-user.target")

    jeff.require_unit_state("traefik.service")
    jared.require_unit_state("simplehttp1.service")
    jared.require_unit_state("simplehttp2.service")
    john.require_unit_state("consul.service")

    john.succeed("consul members")
    john.succeed("consul services register -name jared-simple-http -address http://jared -port 8001")
    john.succeed("consul services register -name jared-simple-http -address http://jared -port 8002")
    out = john.succeed("consul catalog services")
    print(out)

    client.succeed("curl http://john:8500")
    client.succeed("curl http://jared:8001")
    client.succeed("curl http://jared:8002")
    # client.succeed("curl -H 'Host: simple-http-1.jared' http://jeff")
    # client.succeed("curl -H 'Host: simple-http-2.jared' http://jeff")
  '';
})
