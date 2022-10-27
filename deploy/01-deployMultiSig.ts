import { network, ethers, deployments, getNamedAccounts } from "hardhat"
import { developmentChains, networkConfig } from "../helper-hardhat-config"
import { verify } from "../utils/verify"
import { ACCOUNTS } from "../constants" // specify your list of wallet accounts in constants.ts

const deployMultiSig = async () => {
  const { deploy, log } = deployments
  const { deployer } = await getNamedAccounts()
  const localAccounts = await ethers.getSigners()

  let accounts: string[]

  if (developmentChains.includes(network.name)) {
    accounts = localAccounts.slice(0, 3).map((account) => account.address)
  } else {
    accounts = ACCOUNTS
  }

  log("Deploying Multisig wallet contract...")
  const args: any[] = [
    ethers.BigNumber.from((accounts.length * 2) / 3),
    accounts,
  ]
  const chainId = network.config.chainId || 31337

  const multiSig = await deploy("MultiSigWallet", {
    log: true,
    args: args,
    from: deployer,
    waitConfirmations: networkConfig[chainId].blockConfirmations || 1,
  })

  log(`Contract deployed at ${multiSig.address}`)

  if (!developmentChains.includes(network.name)) {
    log(`Verifying contract...`)
    await verify(multiSig.address, args)
  }
}

export default deployMultiSig

deployMultiSig.tags = ["main", "multisig"]
