function isPayableMatch(payable, itemJson) {
  return payable.getPayableid().toNumber() == itemJson['payableId'] &&
    payable.getEngagementid().toNumber() == itemJson['engagementId'] &&
    payable.getObligatoraddress().toAddress().toLowerCase() == itemJson['obligatorAddress'].toLowerCase() &&
    payable.getClaimoraddress().toAddress().toLowerCase() == itemJson['claimorAddress'].toLowerCase() &&
    payable.getTokenaddress().toAddress().toLowerCase() == itemJson['tokenAddress'].toLowerCase() &&
    payable.getAmount().toNumber() == itemJson['amount'] &&
    payable.getPayableduetimestamp().toNumber() == itemJson['payableDueTimestamp'];
}

function searchPayables(items, itemJson) {
  return items.filter(item => isPayableMatch(item, itemJson));
}

function printPayables(items) {
  return items.forEach(item => console.log(getPayableJson(item)));
}

function getPayableJson(payable) {
  return {
    payableId: payable.getPayableid().toNumber(),
    engagementId: payable.getEngagementid().toNumber(),
    obligatorAddress: payable.getObligatoraddress().toAddress(),
    claimorAddress: payable.getClaimoraddress().toAddress(),
    tokenAddress: payable.getTokenaddress().toAddress(),
    amount: payable.getAmount().toNumber(),
    payableDueTimestamp: payable.getPayableduetimestamp().toNumber()
  };
}

module.exports = {
  searchPayables: searchPayables,
  getPayableJson: getPayableJson,
  printPayables: printPayables
};
