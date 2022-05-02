peer chaincode install -n votecc -v 1.1 -p /opt/gopath/src/github.com/hyperledger/fabric-samples/votechaincode/ --lang node
CORE_PEER_ADDRESS=peer2-org1:8051 peer chaincode install -n votecc -v 1.1 -p /opt/gopath/src/github.com/hyperledger/fabric-samples/votechaincode/ --lang node

peer chaincode instantiate -C mychannel -n votecc -v 1.1 -c '{"Args": ["init"]}' -o orderer1-org0:7050 --tls --cafile /tmp/hyperledger/org1/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

peer chaincode query -C mychannel -n votecc -c '{"Args":["getElection", "1"]}'