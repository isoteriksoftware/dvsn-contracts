-include .env

NETWORK_ARGS := --rpc-url $(POLYGON_RPC_URL) --gas-price 25000000000 --private-key $(PRIVATE_KEY) --broadcast -vvvvv

deploy-voter-registry:
	@forge script script/DeployVoterRegistry.s.sol:DeployVoterRegistry $(NETWORK_ARGS)

deploy-party-registry:
	@forge script script/DeployPartyRegistry.s.sol:DeployPartyRegistry $(NETWORK_ARGS)