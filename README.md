# shipyard-contract-audit

This repo contains contracts for the Shipyard project. Here's a brief overview of the architecture to help you understand how it's setup:

We have 3 different contracts (listed in the order they are called):
1) ShipyardOneClickCurve (proof of concept was deployed here: https://arbiscan.io/address/0xE644A77b050DE45233716Db3aF2E2f0CC56206B8#code)
2) ShipyardVault (proof of concept was deployed here: https://arbiscan.io/address/0x573f5Bc50733D648261Aea56e1c530D8b1C0C408#code)
3) StrategyCurveLP (proof of concept was deployed here: https://arbiscan.io/address/0xe1ca57D084ce6A810f2b2cF964Db0D691cAABAE5#code)

<br />

## OneClick

This is the entrypoint contract that our dApp will first call. 

It allows the user to pass in one of a few token input options. For example, if a vault is a liquidity pool between USDC and USDT and the vault token is USDC-USDT-LP, we would allow the user to give us any one of those 3 tokens. This contract is responsible for doing the swapping and conversion to make this possible.

<br />

## Vault

This is the contract that controls the ERC-20 token ('ship' token) issued.

<br />

## Strategy

This is where the meat of the logic resides. It is responsible for handling the actual deposit/withdraw interaction logic as well as "harvest" which is the term for when we claim rewards and auto-compound them.

The included strategy is Curve-specific.
