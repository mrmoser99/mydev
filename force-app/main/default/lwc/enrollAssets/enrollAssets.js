/**
 * @description       : LWC component to Show Assets Screen. 
 * @author            : Surbhi Goyal : Traction on Demand
 * @group             : Kritika Sharma & Surbhi Goyal :  Traction on Demand
 * @last modified on  : 15-06-2022
 * @last modified by  : Kritika Sharma
**/
import { LightningElement,api,wire } from 'lwc';
import getAssetDetails from '@salesforce/apex/EnrollController.getAssetDetails';
import getEndUserData from '@salesforce/apex/EnrollController.getEndUserData';
import getInstallAddresses from '@salesforce/apex/CustomerInstallAddresses.getAddresses';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import ENROLL_ASSET_ADDRESS_MESSAGE from '@salesforce/label/c.ENROLL_ASSET_ADDRESS_MESSAGE';
import ENROLL_ASSET_ADDRESS_TITLE from '@salesforce/label/c.ENROLL_ASSET_ADDRESS_TITLE';

export default class EnrollAssets extends LightningElement {
    label = {
        ENROLL_ASSET_ADDRESS_MESSAGE,
        ENROLL_ASSET_ADDRESS_TITLE
    };

    statelist = [
        {value: '', label: ''},
        {value: 'AL', label: 'AL'},
        {value: 'AK', label: 'AK'},
        {value: 'AZ', label: 'AZ'},
        {value: 'AR', label: 'AR'},
        {value: 'CA', label: 'CA'},
        {value: 'CO', label: 'CO'},
        {value: 'CT', label: 'CT'},
        {value: 'DE', label: 'DE'},
        {value: 'DC', label: 'DC'},
        {value: 'FL', label: 'FL'},
        {value: 'GA', label: 'GA'},
        {value: 'HI', label: 'HI'},
        {value: 'ID', label: 'ID'},
        {value: 'IL', label: 'IL'},
        {value: 'IN', label: 'IN'},
        {value: 'IA', label: 'IA'},
        {value: 'KS', label: 'KS'},
        {value: 'KY', label: 'KY'},
        {value: 'LA', label: 'LA'},
        {value: 'ME', label: 'ME'},
        {value: 'MD', label: 'MD'},
        {value: 'MA', label: 'MA'},
        {value: 'MI', label: 'MI'},
        {value: 'MN', label: 'MN'},
        {value: 'MS', label: 'MS'},
        {value: 'MO', label: 'MO'},
        {value: 'MT', label: 'MT'},
        {value: 'NE', label: 'NE'},
        {value: 'NV', label: 'NV'},
        {value: 'NH', label: 'NH'},
        {value: 'NJ', label: 'NJ'},
        {value: 'NM', label: 'NM'},
        {value: 'NY', label: 'NY'},
        {value: 'NC', label: 'NC'},
        {value: 'ND', label: 'ND'},
        {value: 'OH', label: 'OH'},
        {value: 'OK', label: 'OK'},
        {value: 'OR', label: 'OR'},
        {value: 'PA', label: 'PA'},
        {value: 'PR', label: 'PR'},
        {value: 'RI', label: 'RI'},
        {value: 'SC', label: 'SC'},
        {value: 'SD', label: 'SD'},
        {value: 'TN', label: 'TN'},
        {value: 'TX', label: 'TX'},
        {value: 'UT', label: 'UT'},
        {value: 'VT', label: 'VT'},
        {value: 'VA', label: 'VA'},
        {value: 'WA', label: 'WA'},
        {value: 'WV', label: 'WV'},
        {value: 'WI', label: 'WI'},
        {value: 'WY', label: 'WY'}
    ];

    @api oppId;
    @api editMode;

    newAddressModal=false;

    addAddressRowKey;

    modalStreetOne;
    modalStreetTwo;
    modalCity;
    modalState;
    modalZip;
    modalCountry;

    loading=false;
    isLoading=false;
    isEdited=true;
    assetLocationOptions=[];
    deliveryDateOptions=[];
    @api assetsList = [];
    assetTableHide=true;

    //End User Account Name
    EndUserAccountName;

    @wire(getAssetDetails, {opportunityId: '$oppId'})
    wiredGetAssetDetails({ error, data }){
        if (data) {
            console.log('data assets::'+JSON.stringify(data));
            this.assetsList = [];
            var assetLen = 0;
            for(var i=0; i<data.length; i++) {
                assetLen = i+1;

                // If an existing address had been selected, this has to match the format for it to appear as selected in the picklist.
                var fullAddress = '';
                fullAddress = data[i].Planned_Install_Street__c != null ? fullAddress + data[i].Planned_Install_Street__c : fullAddress;
                fullAddress = data[i].Planned_Install_City__c != null ? fullAddress + ', ' + data[i].Planned_Install_City__c : fullAddress;
                fullAddress = data[i].Planned_Install_State__c != null ? fullAddress + ', ' + data[i].Planned_Install_State__c : fullAddress;
                fullAddress = data[i].Planned_ZIP_Code__c != null ? fullAddress + ', ' + data[i].Planned_ZIP_Code__c : fullAddress;

                // Identify if a service fee has been added in a related record.
                var assetServiceFee = '';
                var serviceFeeId = '';
                if(data[i].Related_App_Line_Item__c != null){
                    if(data[i].Related_App_Line_Item__r.Amount__c != null) {
                        assetServiceFee = data[i].Related_App_Line_Item__r.Amount__c;
                        serviceFeeId = data[i].Related_App_Line_Item__c;
                    }
                }

                // Compile the asset list, merging the related fee into it.
                this.assetsList.push({
                    assets: assetLen,
                    assetLocation: fullAddress,
                    deliveryDate: data[i].Planned_Install_Date__c,
                    id: data[i].Id,
                    key: assetLen,
                    name: data[i].Name,
                    opportunity: this.oppId,
                    serialNumber: data[i].Serial_Number__c,
                    serviceFee: assetServiceFee,
                    serviceFeeId: serviceFeeId,
                    taxExempt: data[i].Tax_Exempt__c
                });
            }

            // Display the assets if they exist.
            if(data.length == 0){
                this.assetTableHide = true;
            } else {
                this.assetTableHide = false;
            }
        } else if (error) {

        }
    }

    connectedCallback(){

        // Get the install addresses this customer has used before.
        getInstallAddresses({oppId: this.oppId}).then(result =>{
            if(result){

                // Loop through and add all the options.
                let options = [];
                for(var key in result){
                    options.push({'label': result[key], 'value': key});
                }

                // Add a default option at the bottom to add a new address.
                options.push({'label': 'Add New Address', 'value': 'Add New Address'});
                options.push({'label': 'No Address', 'value': ''});

                // Populate the picklist field.
                this.assetLocationOptions = options;
            }
        });

        getEndUserData({oppId:this.oppId}).then(data =>{
            console.log('End User Account Name:::'+this.EndUserAccountName);
            if (data) {
                this.EndUserAccountName=data.End_User__r.Name;
            }
        });
    }

    handleAssetLocationChange(event){
        if(event.detail.value=='Add New Address'){
            this.newAddressModal=true;
            this.addAddressRowKey=event.target.name;
            console.log('this.newAddressModal:::'+this.newAddressModal);
        } else {
            console.log('event.dataId::'+event.target.name);
            for(var i=0;i<this.assetsList.length;i++){
                console.log('this.assetsList[i].key:::'+this.assetsList[i].key);
                if(this.assetsList[i].key==event.target.name){
                    console.log('this.assetsList[i].assetLocation:::'+event.detail.value);
                    this.assetsList[i].assetLocation=event.detail.value;
                    console.log('this.assetsList[i].assetLocation:::'+this.assetsList[i]);
                }
            }
        }
        console.log('this.assetLocationOptions::'+JSON.stringify(this.assetLocationOptions));     
    }

    modalClose(){
        this.isLoading = false;
        this.newAddressModal = false;
    }

    modalAddAddress(){

        // Validate required fields.
        var addressValid = true;
        if(this.modalStreetOne == null || this.modalStreetOne == ''){
            addressValid = false;
        }else if(this.modalCity == null || this.modalCity == ''){
            addressValid = false;
        }else if(this.modalState == null || this.modalState == ''){
            addressValid = false;
        }else if(this.modalZip == null || this.modalZip == '') {
            addressValid = false;
        }

        // Stop the saving process.
        if(addressValid == false){

            // Immediate feedback
            const evt = new ShowToastEvent({
                title:      ENROLL_ASSET_ADDRESS_TITLE,
                message:    ENROLL_ASSET_ADDRESS_MESSAGE,
                variant:    'error',
                duration:   10000
            });
            this.dispatchEvent(evt);
            return;
        }

        // Save the address.
        var fullAddress = '';
        fullAddress = this.modalStreetOne != null ? fullAddress + this.modalStreetOne : fullAddress;
        fullAddress = this.modalStreetTwo != null ? fullAddress + ' ' + this.modalStreetTwo : fullAddress;
        fullAddress = this.modalCity != null ? fullAddress + ', ' + this.modalCity : fullAddress;
        fullAddress = this.modalState != null ? fullAddress + ', ' + this.modalState : fullAddress;
        fullAddress = this.modalZip != null ? fullAddress + ', ' + this.modalZip : fullAddress;
        fullAddress = this.modalCountry != null ? fullAddress + ', ' + this.modalCountry : fullAddress;

        this.assetLocationOptions.splice(this.assetLocationOptions.length-1, 1);
        this.assetLocationOptions.push({'label': fullAddress, 'value': fullAddress});
        this.assetLocationOptions.push({'label': 'Add New Address', 'value': 'Add New Address'});

        for(var i=0; i<this.assetsList.length; i++){
            if(this.assetsList[i].key == this.addAddressRowKey){
                this.assetsList[i].assetLocation = fullAddress;
            }
        }
        this.modalClose();
    }

    handleStreetOneChange(event){
        this.modalStreetOne = event.detail.value;
        
    }
    handleCityChange(event){
        this.modalCity = event.detail.value;
    }

    handleZipChange(event){
        this.modalZip = event.detail.value;
    }

    handleStreetTwoChange(event){
        this.modalStreetTwo = event.detail.value;
    }

    handleStateChange(event){
        this.modalState = event.detail.value;
    }

    handleCountryChange(event){
        this.modalCountry = event.detail.value;
    }

    handleSerialNumberChange(event){
        for(var i=0; i<this.assetsList.length; i++){
            if(this.assetsList[i].id == event.target.name){
                this.assetsList[i].serialNumber = event.detail.value;
            }
        }
    }

    handleDeliveryDateChange(event){
        for(var i=0; i<this.assetsList.length; i++){
            if(this.assetsList[i].id == event.target.name){
                this.assetsList[i].deliveryDate = event.detail.value;
            }
        }
    }

    handleServiceFeeChange(event){
        for(var i=0; i<this.assetsList.length; i++){
            if(this.assetsList[i].id == event.target.name){

                // Capture the user input.
                var newServiceFee = Number(event.detail.value).toString();

                // Require positive values only.
                if(newServiceFee != null && newServiceFee < 0){
                    newServiceFee = newServiceFee * -1;
                    event.target.value = newServiceFee;
                }

                // Track the value.
                this.assetsList[i].serviceFee = newServiceFee;
            }
        }
    }

    handleTaxExemptChange(event){
        for(var i=0; i<this.assetsList.length; i++){
            if(this.assetsList[i].id == event.target.name){
                this.assetsList[i].taxExempt = event.detail.checked;
            }
        }
    }
}