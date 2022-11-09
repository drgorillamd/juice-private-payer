- Use JBETHProjectPayer as starting point

- Add an extra layer of privacy via big number:
-- contributions are sent to empty addresses
-- these addresses are the deterministic addresses using create2 from a factory
-- create2 salt is the sender address, a nonce (to use multiple addresses, if wanted), the projecId to fund
-- deployer is a project payer factory
-- this project payer takes the address balance and contribute to the juicebox project

- the payer has sweep functionnalities: the sender address can retrieve any erc20 or eth in this deposit address