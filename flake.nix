{
 	description = "Setup with niri + noctalia";
	inputs = {
		nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
		noctalia = {
		 	url = "github:noctalia-dev/noctalia";
			inputs.nixpkgs.follows = "nixpkgs";
		};
		home-manager = {
			url = "github:nix-community/home-manager";
			inputs.nixpkgs.follows = "nixpkgs";
		};

	};
	outputs =  { self, nixpkgs, noctalia, home-manager, ... }@inputs: {
		nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs; };
			modules = [
				./hardware-configuration.nix
				./configuration.nix
				inputs.noctalia.nixosModules.default
				home-manager.nixosModules.home-manager
				{
					home-manager.useGlobalPkgs = true;
					home-manager.useUserPackages = true;
					home-manager.users.surya = import ./home.nix;
				}
			];
		};
	};
}
