<template>
   <v-container style="background-color:#ffffff;color:#000000;"> 
        <div id="component-profile">
          <button @click="connectWalletHandle()" className="button" 
            style="background-color:#000000;color:#ffffff;padding:5px; border-radius: 5px; font-size:12px">
            Connect Wallet</button>
          <h2>{{statusMsg}}</h2>


        <div id="uploadForm" name="uploadForm" ref="uploadForm" style="display:none">
          <v-img :src="currentImg" style="width:48px;height:48px;"/><br/>
          <label>File<input type="file" id="file" ref="file" @change="onChangeFileUpload()"/></label>
          <button @click="submitForm()" 
            style="background-color:#000000;color:#ffffff;padding:5px; border-radius: 5px;font-size:12px">Add New</button><br/>
          <br/><br/>
          <div id="app">
            <table border="1">
              <tbody>
                <tr v-if="items.length > 0" v-for="(item, index) in items" :key="index" >
                  <td style="padding:5px">{{index + 1}}</td>
                  <td style="padding:5px">
                    <v-img :src="item.name" style="width:16px;height:16px;"/>
                  </td>
                  
                  <td style="padding:5px">
                    <button type="button" @click="editItem(item.tokenId, item.name)" 
                    style="background-color:#000000;color:#ffffff;padding:5px; border-radius: 5px;font-size:12px">
                      Edit
                    </button>
                  </td>
                  <td style="padding:5px">
                    <button type="button" @click="removeItem(item.tokenId)" 
                    style="background-color:#000000;color:#ffffff;padding:5px; border-radius: 5px;font-size:12px">
                      Remove
                    </button>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>




        </div>
        
        
        <div id="editForm" name="editForm" ref="editForm" style="display:none">
          
          <v-img :src="currentImg2" style="width:48px;height:48px;"/><br/>
          <label>File<input type="file" id="file2" ref="file2" @change="onChangeFileUpload2()"/></label><br/><br/>
          <button @click="cancelUpdate()"
            style="background-color:#000000;color:#ffffff;padding:5px; border-radius: 5px;font-size:12px">Cancel</button>
          <button @click="submitUpdate()"
            style="background-color:#000000;color:#ffffff;padding:5px; border-radius: 5px;font-size:12px">Update</button><br/>
        </div>        
        

 




        </div>
    </v-container>
</template>

<script>
import Web3 from 'web3';
import json from '../json/contracts.json';

export default {
  name: 'MyWallet',
  
  data(){
    return {
      statusMsg: '',
      myAccAddress: '',
      currentImg: '',
      currentImg2: '',
      currentTokenIds: '',
      contractAddress: '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9',
      pinata_api_key: '',
      pinata_secret_api_key: '',
      blockchain_network: 'http://127.0.0.1:8545/',
      abiJSON: json,
       items: [
       
      ]
    }
  },
   
  methods: {
      cancelUpdate(){
         this.$refs.uploadForm.style.display = "block";
        this.$refs.editForm.style.display = "none";
      },
      editItem(tokenIds, imgUrl){
        this.currentImg2 = imgUrl;
        this.currentTokenIds = tokenIds;
        this.$refs.uploadForm.style.display = "none";
        this.$refs.editForm.style.display = "block";
      },
      updateItem(ipfshash){
         var imgUrl="https://gateway.pinata.cloud/ipfs/"+ipfshash;
            console.log(imgUrl);
        
            try{
                var web3 = new Web3(new Web3.providers.HttpProvider(this.blockchain_network));

                  //contract instance
                var contract = new web3.eth.Contract(this.abiJSON, this.contractAddress);
                
                contract.methods.update (this.currentTokenIds, imgUrl).send( {from: this.myAccAddress[0]}).then( (tx) => { 
                  console.log("Transaction: ", tx); 
                  this.getAllToken();
                });
              }
              catch (err){
                console.log(err.message); 
                $statusMsg = err.message;
              }
      }, 

      AddItem(imgUrl, tokenIds){
        this.items.push({
          name: imgUrl+'',
          tokenId: tokenIds
        })
      },
   
      deleteAll() {
        this.items.splice(this.items)
      },
      
    

      getTokenId(currentId, lastId){
        console.log(currentId); 
         var web3 = new Web3(new Web3.providers.HttpProvider(this.blockchain_network));

          //contract instance
        var contract = new web3.eth.Contract(this.abiJSON, this.contractAddress);
        contract.methods.exists (currentId).call().then( (isExists) => { 
            console.log(currentId+" isExists? "+isExists); 

            if (isExists){
              contract.methods.tokenURI (currentId).call().then( (tokenURI) => { 
                  console.log(currentId+" tokenURI: "+tokenURI); 
                  try{
                  this.AddItem(tokenURI, currentId);
                  }
                  catch(err){
                      console.log(err);
                  }
                   if (currentId < lastId){
                      this.getTokenId(currentId+=1, lastId);
                    }
              });

            }else{
              if (currentId < lastId){
                this.getTokenId(currentId+=1, lastId);
              }
            }

        });
      },
      getAllToken(){
        this.$refs.uploadForm.style.display = "block";
        this.$refs.editForm.style.display = "none";
         var web3 = new Web3(new Web3.providers.HttpProvider(this.blockchain_network));

          //contract instance
        var contract = new web3.eth.Contract(this.abiJSON, this.contractAddress);
        
        contract.methods.lastIndex ().call().then( (lastId) => { 
            console.log("lastIndex: ", lastId); 
            this.deleteAll();
            
            this.getTokenId(0, lastId);

        });
      },
        async connectMetamask(){
        if (typeof window !== "undefined" && typeof window.ethereum !== "undefined" ){
            try{
              this.myAccAddress=await window.ethereum.request({method: "eth_requestAccounts"});
              window.ethereum.enable();
              this.statusMsg = "My Account: "+this.myAccAddress;
              this.$refs.uploadForm.style.display = "block";
               this.getAllToken();
            }
            catch (err){
              console.log(err.message); 
              $statusMsg = err.message;
            }
        }else{
          console.log("Please install metamask");
          this.statusMsg = "Please install metamask";
        }
      }, 
      removeItem(tokenId){
       var web3 = new Web3(new Web3.providers.HttpProvider(this.blockchain_network));

          //contract instance
        var contract = new web3.eth.Contract(this.abiJSON, this.contractAddress);
       
         contract.methods.remove (tokenId).call().then( (tx) => { 
             console.log("Transaction: ", tx); 
            this.getAllToken();
        }).catch(error => {
              //handle error here
              console.log(error);
          });
      },
      async commitToWallet (ipfshash) {
            var imgUrl="https://gateway.pinata.cloud/ipfs/"+ipfshash;
            console.log(imgUrl);
        
            try{
             
                 var web3 = new Web3(new Web3.providers.HttpProvider(this.blockchain_network));

                  //contract instance
                var contract = new web3.eth.Contract(this.abiJSON, this.contractAddress);
                
                contract.methods.add (imgUrl).send( {from: this.myAccAddress[0]}).then( (tx) => { 
                  console.log("Transaction: ", tx); 
                  this.getAllToken();
                });
              }
              catch (err){
                console.log(err.message); 
                this.statusMsg = err.message;
              }
         
          
        
      },
        testPinata(){
          
          var url2 = "https://api.pinata.cloud/data/testAuthentication";
           this.$axios.$get(url2, {
            headers: {
               'pinata_api_key': this.pinata_api_key,
               'pinata_secret_api_key': this.pinata_secret_api_key
            }
          })
          .then(response => {
              //handle your response here
              console.log(response);
          })
          .catch(error => {
              //handle error here
              console.log(error);
          });
        },

        submitUpdate(){
          
           let formData = new FormData();
            formData.append('file', this.file2);
            this.$axios.$post('https://api.pinata.cloud/pinning/pinFileToIPFS',
                formData,
                {
                headers: {
                    'pinata_api_key': this.pinata_api_key,
                    'pinata_secret_api_key': this.pinata_secret_api_key
                }
              }
            ).then(resp => {
              console.log(resp.IpfsHash);
                
             
              this.updateItem(resp.IpfsHash);
              


            })
            .catch(err => {
              console.log('FAILURE!!');
              console.log(err);
            });
            
      },
       submitForm(){
          
          let formData = new FormData();
            formData.append('file', this.file);
            this.$axios.$post('https://api.pinata.cloud/pinning/pinFileToIPFS',
                formData,
                {
                headers: {
                    'pinata_api_key': this.pinata_api_key,
                    'pinata_secret_api_key': this.pinata_secret_api_key
                }
              }
            ).then(resp => {
              console.log(resp.IpfsHash);
                
             
              this.commitToWallet(resp.IpfsHash);
              


            })
            .catch(err => {
              console.log('FAILURE!!');
              console.log(err);
            });
            
      },
      onChangeFileUpload(){
        this.file = this.$refs.file.files[0];
        this.currentImg = URL.createObjectURL(this.file);
        console.log(this.currentImg);

      },

       onChangeFileUpload2(){
        this.file2 = this.$refs.file2.files[0];
         this.currentImg2 = URL.createObjectURL(this.file2);
        console.log(this.currentImg2);
      },
    async connectWalletHandle () {
      this.connectMetamask();
    }


  },
  created: () => {
    console.log("On Start");
    

  },
  destroyed: () => { 
      console.log("On Destroy");
  }
}




</script>

<style>

</style>