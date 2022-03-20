const { ethers } = require('hardhat');
const { BigNumber } = ethers;
const { ecsign } = require('ethereumjs-util');

const {
  utils: { keccak256, defaultAbiCoder, toUtf8Bytes, solidityPack, hexlify }
} = ethers;
const ZERO_ADDRESS = ethers.constants.AddressZero;

// Defaults to e18 using amount * 10^18
function getBigNumber(amount, decimals = 18) {
  return BigNumber.from(amount).mul(BigNumber.from(10).pow(decimals));
}

async function getSignatures(signers, hexCallData) {
  const rs = [];
  const ss = [];
  const vs = [];

  for (const signer of signers) {
    const flatSig = await signer.signMessage(ethers.utils.arrayify(ethers.utils.keccak256()));
    const splitSig = ethers.utils.splitSignature(flatSig);

    rs.push(splitSig.r);
    ss.push(splitSig.s);
    vs.push(splitSig.v);
  }

  return { rs, ss, vs };
}

// this function is for EIP 191
async function getFlatSignature(signer, hexCallData) {
  // const flatSig = await signer.signMessage(hexCallData);
  // const flatSig = await signer.signMessage(ethers.utils.arrayify(ethers.utils.keccak256(hexCallData)));
  const flatSig = await signer.signMessage(ethers.utils.arrayify(hexCallData));
  return flatSig;
}

function getDomainSeparator(name, chainId, tokenAddress) {
  return keccak256(
    defaultAbiCoder.encode(
      ['bytes32', 'bytes32', 'bytes32', 'uint256', 'address'],
      [
        keccak256(toUtf8Bytes('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)')),
        keccak256(toUtf8Bytes(name)),
        keccak256(toUtf8Bytes('1')),
        chainId,
        tokenAddress
      ]
    )
  );
}

function getApprovalDigest(contractName, contractAddress, chainId, types, values) {
  const DOMAIN_SEPARATOR = getDomainSeparator(contractName, chainId, contractAddress);

  return keccak256(
    solidityPack(
      ['bytes1', 'bytes1', 'bytes32', 'bytes32'],
      ['0x19', '0x01', DOMAIN_SEPARATOR, keccak256(defaultAbiCoder.encode(types, values))]
    )
  );
}

function getEIP712Signature(digest, privateKey) {
  const { v, r, s } = ecsign(Buffer.from(digest.slice(2), 'hex'), Buffer.from(privateKey.slice(2), 'hex'));
  const sig = hexlify(r) + hexlify(s).slice(2) + hexlify(v).slice(2);
  return sig;
}

module.exports = {
  ZERO_ADDRESS,
  getBigNumber,
  getSignatures,
  getFlatSignature,
  getDomainSeparator,
  getApprovalDigest,
  getEIP712Signature
};
