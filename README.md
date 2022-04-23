두 개의 터미널에서 cli container에 접속
todo: sh로 접속하면 채널 접속 내역들 유지할 수 있어 보이긴 한데 아직 테스트는 안 해 봄
docker exec -it cli-org1 bash
docker exec -it cli-org2 bash

bringUpContainers.sh에서 만든 channel.tx 파일을 cli에서 접근할 수 있도록 복사
---컨테이너가 아니라 로컬에서 실행!---
cd /tmp/hyperledger
cp org0/orderer/channel.tx org1/peer1/assets/

cli-org1 컨테이너에서 채널을 만든다.
Received block: 0 출력되면 성공
peer channel create -c mychannel -f /tmp/hyperledger/org1/peer1/assets/channel.tx -o orderer1-org0:7050 --outputBlock /tmp/hyperledger/org1/peer1/assets/mychannel.block --tls --cafile /tmp/hyperledger/org1/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

peer1-org1에서 만들어진 mychannel.block을 통해 채널에 join
peer2-org1에서 만들어진 mychannel.block을 통해 채널에 join
peer channel join -b /tmp/hyperledger/org1/peer1/assets/mychannel.block
CORE_PEER_ADDRESS=peer2-org1:7051 peer channel join -b /tmp/hyperledger/org1/peer1/assets/mychannel.block

cli-org1에서 만든 채널 블록을 이용해 join하기 위해 복사
---컨테이너가 아니라 로컬에서 실행!---
cd /tmp/hyperledger
cp org1/peer1/assets/mychannel.block org2/peer1/assets/

peer1-org2에서 만들어진 mychannel.block을 통해 채널에 join
peer2-org2에서 만들어진 mychannel.block을 통해 채널에 join
peer channel join -b /tmp/hyperledger/org2/peer1/assets/mychannel.block
CORE_PEER_ADDRESS=peer2-org2:7051 peer channel join -b /tmp/hyperledger/org2/peer1/assets/mychannel.block

각 cli에서 아래 getinfo를 실행했을 때 블록체인 정보가 출력되면 성공
peer channel getinfo -c mychannel

체인코드 설치,,, node는 dependency 문제인지 실행 안 되고 go로 했을 때는 됨
cli-org1에서 org1의 피어들에 go로 설치

peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/abac/go/
CORE_PEER_ADDRESS=peer2-org1:7051 peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/abac/go/

cli-org2에서 org2의 피어들에 체인코드 설치
peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/abac/go/
CORE_PEER_ADDRESS=peer2-org2:7051 peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric-samples/chaincode/abac/go/

chaincode폴더 내에 여러 체인코드들이 있다.
go로 설정된 부분들 -p에 설정하고 -n의 네임을 수정해서 여러가지 설치할 수 있다.
fabcar chaincode_example02 테스트 해봄(abac랑 동작은 똑같은 듯?)

튜토리얼 과정에서 설정해 놓은 값 때문에 abac는 org2에서만 init이 가능하다. 나중에 제한 조건 걸고 싶으면 이렇게 하면 될 듯
instantiate 후에는 체인코드를 활용할 수 있다.
peer chaincode instantiate -C mychannel -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -o orderer1-org0:7050 --tls --cafile /tmp/hyperledger/org2/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

아까 init에서 초기화 한 a 값인 100을 query
CORE_PEER_ADDRESS를 설정해서 org1의 다른 피어에서 실행 가능
org2-cli에서는 CORE_PEER_ADDRESS org를 수정
peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'
CORE_PEER_ADDRESS=peer2-org1:7051 peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'

chaincode invoke를 통해 invoke 함수를 실행할 수 있다.
아래는 a에서 10을 가져다가 b에 10 주는 코드
실행하는 컨테이너에 따라 org1 org2는 설정해서 실행, 실행 후 query로 다시 확인할 수 있음
peer chaincode invoke -C mychannel -n mycc -c '{"Args":["invoke","a","b","10"]}' --tls --cafile /tmp/hyperledger/org1/peer1/tls-msp/tlscacerts/tls-0-0-0-0-7052.pem

