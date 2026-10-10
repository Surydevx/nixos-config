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

		nixos-fprint = {
      			url = "github:ahbnr/nixos-06cb-009a-fingerprint-sensor";
      			inputs.nixpkgs.follows = "nixpkgs";
    		};

	};
	outputs =  { self, nixpkgs, noctalia, home-manager, nixos-fprint, ... }@inputs: {
		nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
			system = "x86_64-linux";
			specialArgs = { inherit inputs; };
			modules = [
				./hardware-configuration.nix
				./configuration.nix
				inputs.noctalia.nixosModules.default
				nixos-fprint.nixosModules.open-fprintd
        	    nixos-fprint.nixosModules.python-validity
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
