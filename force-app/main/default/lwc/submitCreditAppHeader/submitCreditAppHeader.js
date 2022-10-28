/*
  Author: Kritika Sharma, Traction on Demand
  Date: 09/02/2022.
 */

import { LightningElement, track, wire ,api} from 'lwc';
import getOpportunityField from '@salesforce/apex/CreditApplicationHeaderController.getOpportunityData';

export default class SubmitCreditAppHeader extends LightningElement {
  displayQuoteHeaderModel = true;
  displayQuoteHeaderViewModel = false;
  hasQuotes = true;
  isView = true;
  loading = false;
  currentPosition = 0;
  currentAccPosition = 0;
  @api quoteId;
  salesRepName;
  locationName;
  nickName;
  salesrepOptions = [];
  lacationOptions = [];
  relatedAssets = [];
  openAccordionSections = ['Financing Structure'];

  assets = [{
    sectionName: 'asset0',
    assetHeading: 'Asset Details',
    assetNo: 0,
    isFirst: true
  }];

  accessories = [{
    accNo: 0,
    isFirst: true
  }];

  quoteObject = {
    deleteAssets: [],
    isEdit: false,
    isClone: false,
    financeType:'BO',
    paymentFrequency: 'Monthly',
    advPayments: '0'
  };

    handleClick(event){
      this.displayQuoteHeaderModel = false;
      this.displayQuoteHeaderViewModel = true;
    }
  
    handleBack(event){
      this.displayQuoteHeaderViewModel = false;
      this.displayQuoteHeaderModel = true;
    }
    connectedCallback() {
      //this.loading = false;
    }

    @wire(getOpportunityField, {quoteIds: ''})
    wiredgetQuoteRecord({ error, data }) { 
      if (data) {
        this.salesrepOptions.push({'label':data.Opportunity.Sales_Rep_Name__c, 'value':data.Opportunity.Sales_Rep_Name__c});
        this.lacationOptions.push({'label':data.Opportunity.Location__c, 'value':data.Opportunity.Location__c});
        this.salesRepName=data.Opportunity.Sales_Rep_Name__c;
        this.locationName=data.Opportunity.Location__c;
        this.nickName=data.Opportunity.Nickname__c;
        const startLocation = this.template.querySelector('.startLocation');
          if (startLocation) {
            startLocation.value = this.locationName;
          }
          const startSalesRep = this.template.querySelector('.startSalesrep');
          if (startSalesRep) {
            startSalesRep.value = this.salesRepName;
          }
        
      } else if (error) {  
        
      }
    }
  
  //Asset component handlers
  handleAddAsset(event) {
    this.loading = true;
    this.currentPosition++;
    this.assets.push({sectionName: 'asset' + this.currentPosition, assetHeading: 'Asset Details', assetNo: this.currentPosition, isFirst: false});
    //This timeout is needed since updating the accordion sections on the screen is async
    setTimeout(() => {
        this.openAccordionSections = ('asset' + this.currentPosition);
        }, 500);
    this.loading = false;
  }

  handleDeleteAsset(event) {
    this.loading = true;
    console.log('got here');
    console.log(event.detail);
    this.deleteRelatedAccessories(this.assets[event.detail]);
    if (typeof this.assets[event.detail].Id !== 'undefined') {
        this.quoteObject.deleteAssets.push({Id:this.assets[event.detail].Id});
    }
    this.assets.splice(event.detail, 1);

    this.currentPosition--;
    for (let i = 0; i < this.assets.length; i++) {
        this.assets[i].assetNo = i;
    }
    this.updateAssetPicklist();
    console.log(this.assets);
    this.loading = false;
  }
  handleUpdateAsset(event) {
    this.loading = true;
    this.assets[event.detail.assetNo] = event.detail;
    console.log(JSON.stringify(this.assets));
    this.updateAssetPicklist();
    this.loading = false;
  }

  deleteRelatedAccessories(assets) {
    console.log(assets);
    let tempAcc = JSON.parse(JSON.stringify(this.accessories));
    console.log(tempAcc);
    this.accessories = [];
    for (let i = 0; i < tempAcc.length; i++) {
        if (tempAcc[i].relatedAsset !== assets.make) {
            this.accessories.push(tempAcc[i]);
            this.currentAccPosition--;
        }
    }
    if (this.accessories.length === 0) {
        this.accessories.push({
            accNo: 0,
            isFirst: true
        });
    } else {
        for (let i = 0; i < this.accessories.length; i++) {
            this.accessories[i].accNo = i;
            this.currentAccPosition = i;
        }
        this.accessories[0].isFirst = true;
    }
}
//update picklist values for assets
updateAssetPicklist() {
  this.relatedAssets = [];
  for (let i = 0; i < this.assets.length; i++) {
      if (typeof this.assets[i].make !== 'undefined') {
          this.relatedAssets.push({label: this.assets[i].assetHeading.substring(15, this.assets[i].assetHeading.length), value: this.assets[i].assetHeading.substring(15, this.assets[i].assetHeading.length)});
      }
  }
}

}