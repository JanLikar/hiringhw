{ pkgs ? import <nixpkgs> {} }:
  pkgs.mkShell {
    nativeBuildInputs = with pkgs.buildPackages; [ git minikube kubectl fluxcd kubernetes-helm ];
}

