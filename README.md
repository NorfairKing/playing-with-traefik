# Playing with Traefik

A demonstration of combining traefik and consul, all in a NixOS test..

To run the test:

``` plain
nix build .\#checks.x86_64-linux.test
```

To run the VMs from the test interactively:

``` plain
nix build .\#checks.x86_64-linux.test.driverInteractive
./result/bin/nixos-test-driver
```
