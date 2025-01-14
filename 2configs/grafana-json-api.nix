{
  config,
  pkgs,
  lib,
  ...
}:
let
  writeGo =
    name:
    {
      go ? pkgs.go,
      makeWrapperArgs ? [ ],
      goBuildArgs ? [ ],
      strip ? true,
    }:
    pkgs.writers.makeBinWriter {
      compileScript = ''
        export GO111MODULE=off
        export GOTOOLCHAIN=local
        export GOCACHE="$(pwd)/go-build"

        echo "package main" > main.go
        cat "$contentPath" >> main.go
        ${lib.getExe go} build ${lib.escapeShellArgs goBuildArgs} main.go
        mv main $out
      '';
      inherit makeWrapperArgs strip;
    } name;

  writeGoBin = name: writeGo "/bin/${name}";

  json-api =
    writeGoBin "json-api" { goBuildArgs = [ "-tags=nethttpomithttp2" ]; }
      # go
      ''
        import (
          "log"
          //"net"
          "net/http"
          //"net/url"
          "io"
          "os"
        )

        func main() {
          listen_addr, exists := os.LookupEnv("LISTEN_ADDR")
          if !exists {
            log.Fatal("AUTH_DIR not set")
            os.Exit(1)
          }

          http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
            w.WriteHeader(http.StatusOK)
          })
          http.HandleFunc("/metrics", func(w http.ResponseWriter, r *http.Request) {
            w.Header().Set("Content-Type", "application/json")
            io.WriteString(w, `["test"]`)
          })
          http.HandleFunc("/query", func(w http.ResponseWriter, r *http.Request) {
            w.Header().Set("Content-Type", "application/json")
            io.WriteString(w, `[{
                "type": "table",
                "columns": [
                  {"text":"a","type":"string"},
                  {"text":"b","type":"number"}
                ],
                "rows": [
                  ["a",1],
                  ["b",2],
                  ["c",3],
                  ["d",4],
                  ["e",5]
                ]
              }]`)
          })


          log.Fatal(http.ListenAndServe(listen_addr, nil))
        }
      '';
in
{
  systemd.services.json-api = {
    description = "json-api service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
    path = [ pkgs.apacheHttpd ];

    environment = {
      LISTEN_ADDR = ":6969";
    };

    serviceConfig = {
      ExecStart = lib.getExe json-api;
      DynamicUser = true;

      # Hardening
      CapabilityBoundingSet = [ "" ];
      DeviceAllow = [ "" ];
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      PrivateDevices = true;
      PrivateUsers = true;
      ProcSubset = "pid";
      ProtectClock = true;
      ProtectControlGroups = true;
      ProtectHome = true;
      ProtectHostname = true;
      ProtectKernelLogs = true;
      ProtectKernelModules = true;
      ProtectKernelTunables = true;
      ProtectProc = "invisible";
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictNamespaces = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      SystemCallArchitectures = "native";
      SystemCallFilter = [
        "@system-service"
        "~@privileged"
      ];
      UMask = "0077";
    };
  };
}
