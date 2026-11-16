{
  description = "blkedn-mac: macOS home-manager mirror of the blkedn NixOS config (nvim only, for now)";

  inputs = {
    # The main config. Source of truth: its modules are imported from here, never copied.
    blkedn.url = "github:daschinmoy21/blkedn";

    # Reuse blkedn's pins so the Mac gets exactly the same nvim and plugin versions.
    nixpkgs.follows = "blkedn/nixpkgs";
    home-manager.follows = "blkedn/home-manager";
    nvf.follows = "blkedn/nvf";
  };

  outputs = {
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    mkHome = system:
      home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.${system};
        # blkedn's modules expect `inputs` (they use inputs.nvf).
        extraSpecialArgs = {inherit inputs;};
        modules = [./home.nix];
      };
  in {
    formatter = nixpkgs.lib.genAttrs ["aarch64-darwin" "x86_64-darwin"] (
      system: nixpkgs.legacyPackages.${system}.alejandra
    );

    # Apple Silicon (almost certainly your work Mac) and Intel.
    homeConfigurations = {
      mac = mkHome "aarch64-darwin";
      mac-intel = mkHome "x86_64-darwin";
    };
  };
}
