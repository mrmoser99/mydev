import { LightningElement, wire, api } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

//apex 
//import getTest from "@salesforce/apex/PricingUtils.getTest";
import getUserSite from "@salesforce/apex/PricingUtils.getUserSite";
import getPrograms from "@salesforce/apex/PricingUtils.getPrograms";
import getMakes from "@salesforce/apex/PricingUtils.getMakes";  
import getAssetTypes from "@salesforce/apex/PricingUtils.getAssetTypes";
import getAccessories from "@salesforce/apex/PricingUtils.getAccessories";
import getModels from "@salesforce/apex/PricingUtils.getModels";
import getAsset from "@salesforce/apex/PricingUtils.getAsset";
import getFinancialProducts from "@salesforce/apex/PricingUtils.getFinancialProducts";
import getFinancialProduct from "@salesforce/apex/PricingUtils.getFinancialProduct";
import getPrice from "@salesforce/apex/PricingUtils.getPrice";
import submitCreditApp from "@salesforce/apex/CreditAppUtils.submitCreditApp";
import quickSearch from "@salesforce/apex/CustomerUtils.quickSearch";
import This_is_an_automatically_generate from '@salesforce/label/c.This_is_an_automatically_generate';
import getSubsidies from '@salesforce/apex/PricingUtils.getSubsidies';
import getSalesReps from '@salesforce/apex/PricingUtils.getSalesReps';
import { getRecordNotifyChange } from 'lightning/uiRecordApi';
import submitPreQualCreditApp from "@salesforce/apex/CreditAppUtils.submitPreQualCreditApp";
import {subscribe,unsubscribe,onError,setDebugFlag,isEmpEnabled} from 'lightning/empApi';

import { loadScript } from 'lightning/platformResourceLoader';
import cometd from '@salesforce/resourceUrl/cometd';
import getSessionId from '@salesforce/apex/GenericUtilityClass.getSessionId';
 




// datatable columns
 
const columns = [
    { type: 'text' , fieldName: 'Name' },
];



export default class dDAPITestHarness extends LightningElement {

    termlist = [];

    

    ratelist = [];

    advancelist = [
        {value: '0', label: '0'},
        {value: '1', label: '1'},
        {value: '2', label: '2'},
        {value: '3', label: '3'}
    ];

    frequencylist = [
        {value: 'monthly', label: 'Monthly'},
        {value: 'quarterly', label: 'Quarterly'},
        {value: 'semi-annually', label: 'Semi-Annually'},
        {value: 'annually', label: 'Annually'}
    ];

    financetypelist = [
        {value: 'BO', label: '$1BO'},
        {value: 'FMV', label: 'FMV'}
    ];

    
    programlist = [];
    subsidylist = [];s
    accesorylist = [];
    sitelist = [];
    assettypelist = [];
    makelist =[];
    modelList=[];
    mastlist=[];
    batterylist=[];
    hourlist=[];
    environmentlist=[];
    batterylist=[];
    financialproductlist=[];
    searchresultlist=[];
    searchData=[];
    salesreplist=[];
    
    
    //selected values
    columns=columns;
    userSite;
    subsidyId;
    site;
    program;
    programId;
    accessoryId;
    make;
    makelabel;
    assettype;
    assettypeid;
    model;
    modellabel;
    asset;
    mast;
    hours;
    environment;
    battery;
    term;
    paymentTiming = 'in-arrears';
    rate;
    frequency;
    accountId;
    
    advance;
    financetype;
    financialproduct;
    financialproduct2;
    monthlypayment;
    creditresponse;
    creditresponsepq;
    loadMoreStatus;
    getsubsidy = false;
    assetCondition = 'new';
    salesrepid;



    dealAccountId;
    
    loading=true;
    getAccessories;

    searchSiteName;
    searchProgramId;
    searchAssetId;
    searchMake;
    searchAssetType;
    searchFinanceType;
    triggerAssetTypes;
    searchCustomer;
    selectedCustomer;
    strSearchAccName='';
    

    data = [];
    
    parentQuoteId;

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'sticky'
        });
        this.dispatchEvent(event);
    }

     

    @api channelName = '/event/Credit_Response__e';
    isSubscribeDisabled = false;
    isUnsubscribeDisabled = !this.isSubscribeDisabled;
    subscription = {};

    @api channel = '/event/Credit_Response__e';;
    libInitialized = false;
    sessionId;
    error;

    @wire(getSessionId)
    wiredSessionId({ error, data }) {
        if (data) {
            this.sessionId = data;
            this.error = undefined;
            loadScript(this, cometd)
            .then(() => {
                this.initializeCometD(this.channel);
            });
        } else if (error) {
            this.error = error;
            this.sessionId = undefined;
            console.log('error is: ' + JSON.stringify(this.error));
        }
    }

    // initialize CometD 
    initializeCometD(channel) {
        console.log('1');
        if (this.libInitialized) {
            console.log('2');
            return;
        }
        this.libInitialized = true;
        var lwcThisContext = this;
        var cometdlib = new window.org.cometd.CometD();
        cometdlib.configure({
            url: window.location.protocol + '//' + window.location.hostname + '/cometd/56.0/',
            requestHeaders: { Authorization: 'OAuth ' + this.sessionId},
            appendMessageTypeToURL : false,
            logLevel: 'debug'
        });
        cometdlib.websocketEnabled = false;
        cometdlib.handshake(function(status) {
            console.log('status is: ' + status);
            if (status.successful) {
                console.log('channel:' + channel)
                cometdlib.subscribe(channel, function(message){
                   
                    console.log('New message is: ' + JSON.stringify(message));
                });
                
            } else {
                console.error('Error in handshaking: ' + JSON.stringify(status));
            }
        });
    }

    handleMessage(event){
        console.log('hello msg');
    }
    
    // Tracks changes to channelName text field
    handleChannelName(event) {
        
        this.channelName = event.target.value;
        console.log(this.channelName);
    }

    // Initializes the component
    connectedCallback() {
        // Register error listener
        this.registerErrorListener();
        console.log('dog1');
        this.handleSubscribe();
    }

     // Handles unsubscribe button click
    handleUnsubscribe() {
        this.toggleSubscribeButton(false);

        // Invoke unsubscribe method of empApi
        unsubscribe(this.subscription, (response) => {
            console.log('unsubscribe() response: ', JSON.stringify(response));
            // Response is true for successful unsubscribe
        });
    }

    changeColor(){

        let childComponent = this.template.querySelector('c-child');
        let test = childComponent.childMethod(); 

    }
    // Handles subscribe button click
    handleSubscribe() {

        
        
        console.log('ugh');
        // Callback invoked whenever a new event message is received
        const messageCallback = (response) => {
            console.log('New message received: ', JSON.stringify(response));
            // Response contains the payload of the new message received
            
            //if (response.data.payload.Opportunity__c == '123456789'){
            //    console.log('matched');
            //}
                
        };
        
     

        // Invoke subscribe method of empApi. Pass reference to messageCallback
        subscribe(this.channelName, -1, messageCallback).then((response) => {
            // Response contains the subscription information on subscribe call
            console.log(
                'Subscription request sent to: ',
                JSON.stringify(response.channel)
            );
            this.subscription = response;
            console.log('this sub:' + JSON.stringify(this.subscription));

            this.toggleSubscribeButton(true);
           
        });
    }

   

    toggleSubscribeButton(enableSubscribe) {
        this.isSubscribeDisabled = enableSubscribe;
        this.isUnsubscribeDisabled = !enableSubscribe;
    }

    registerErrorListener() {
        // Invoke onError empApi method
        onError((error) => {
            console.log('Received error from server: ', JSON.stringify(error));
            // Error contains the server-side error
        });
    }

    

    //Wire methods
    /***********************************************************************************************************
    * getUserSIte
    ************************************************************************************************************/
    @wire(getUserSite,{userId : '00578000000ftWq'}) 
        wiredgetUserSite({error, data}){

            console.log('getting sites');

            this.advance = '0'
            this.frequency=  'monthly';

            this.loading = true;
             
            this.data = data;

            var siteList = [];

            if (this.data) {
                 
                var o = JSON.parse(data);
                 
                if (o != null){
                    for (let i = 0; i < o.returnSiteList.length; i++) {
                        
                        let lab = o.returnSiteList[i].name;
                        let val = o.returnSiteList[i].originatingSiteId;

                        siteList.push({label: lab, value: val});

                         
                    } 
                } 

                console.log('done loading site' + JSON.stringify(siteList));
                this.sitelist = siteList;
                console.log('here');
                this.loading = false;
                
            } else if (error) {  
                this.showToast('Something went wrong', error.body.message, 'error');
                this.loading=false;
                this.userSite=undefined;
                return;
            }
             

        }

    /***********************************************************************************************************
    * getPrograms
    ************************************************************************************************************/
    @wire(getPrograms,{ siteName: '$userSite'}) 
        wiredgetPrograms({ error, data }) {
             
            console.log('in getPrograms');
        
            
            this.data = data;
             
            let plist = [];

            if (this.data) {

                console.log('there is data' +  data);
                
                data = JSON.parse(data);
                
                data.forEach(function(element){
                    console.log(element.programName + ' ' + element.programId);
                    plist.push({label: element.programName, value: element.programId});
                    
            });
            } else if (error) {   
                 
                this.showToast('Something went wrong', error.body.message, 'error');
                this.loading=false;
                this.programlist=undefined;
                return;
                
            }
            this.programlist = plist;
            this.loading = false;
            
    }

    
    /***********************************************************************************************************
    * getFinancialProducts
    ************************************************************************************************************/
    @wire(getFinancialProducts,{ programId: '$searchProgramId', financetype: '$searchFinanceType' }) 
        wiredgetFinancialProducts({ error, data }) {
             
            console.log('in getFinancialProducts');
        
            
            this.data = data;
             
            let plist = [];

            if (this.data) {

                console.log('there is data' +  data);
                data = JSON.parse(data);
                let onlyoneid = null;
                data.forEach(function(element){
                    console.log(element.name + ' ' + element.id);
                    plist.push({label: element.name, value: element.id});
                    onlyoneid = element.id;
                    
                });

                if (data.length == 1)
                    this.financialproduct = onlyoneid;

            } else if (error) {   
                 
                this.showToast('Something went wrong', error.body.message, 'error');
                this.loading=false;
                this.financialproductlist=undefined;
                return;
                
            }
            this.financialproductlist = plist;
            
            this.loading = false;
            
    }

    /***********************************************************************************************************
    * getFinancialProduct  populates term
    ************************************************************************************************************/
    @wire(getFinancialProduct,{ programId: '$searchProgramId', productId: '$financialproduct'}) 
        wiredgetFinancialProduct({ error, data }) {
             
            console.log('in getFinancialProduct by id');
             
            let tList = [];
            
            if (data) {

                console.log('there is data for fp' + data);
                 
                let obj = JSON.parse(data);

                let monthArray = obj.data.duration.numberOfmonths;
                let inputs = monthArray.values[0];
                let minimum = inputs.minimum;
                let maximum = inputs.maximum;

                for (let i = minimum; i < maximum + 2 ; i++) {
                    tList.push({label: i.toString(), value: i.toString()});
                }

                this.termlist = tList;

            } else if (error) {   
                 
                this.showToast('Something went wrong', error.body.message, 'error');
                this.loading=false;
                return;
                
            }
            
            this.loading = false;
            
    }

    getSalesReps(event) {

        console.log('in get salesreps ...');

        this.loading = true;

        getSalesReps({ originatingSiteId: this.site })
            .then(result => {
                
                let data = JSON.parse(result);
                console.log('there is data' + data);
                let sList = [];

                data.forEach(function(element){
     
                    sList.push({label: element.name, value: element.id});
                    
                });
                
                this.salesreplist = sList;          
                this.loading = false;

                  
            })
            .catch(error => {
                this.error = error;
                this.loading=false;
                this.showToast('Something went wrong', error.body.message, 'error');
                return;
            });

        

    }

    getSubsidies(event) {
        console.log('in get subsidies ...');

        this.loading = true;

        

        console.log(this.searchProgramId + '-' + this.financialproduct + '-' + this.term + '-' + this.makelabel +
        '-' + this.frequency + '-' + this.modellabel + '-' + 'new' + '-' + this.paymentTiming + '-' + this.financetype);
  
        
        getSubsidies({ programId: this.searchProgramId, productId: this.financialproduct, numberOfMonths: this.term,
        interpolation: 'upper', make : this.makelabel , paymentFrequency: this.frequency,  assetCondition: 'new',
        paymentTiming : this.paymentTiming, financeType : this.financetype })
            .then(result => {``
                
                
                console.log('result is: ' + result);
                this.loading = false;

                  
            })
            .catch(error => {
                this.error = error;
                this.loading=false;
                this.showToast('Something went wrong', error.body.message, 'error');
                return;
            });

        
    }


    
    /***********************************************************************************************************
    * getMakes
    ************************************************************************************************************/
    @wire(getMakes,{ programId: '$searchProgramId'}) 
        wiredgetMakes({ error, data }) {
            
            this.loading=true;

            console.log('in getMakes');
            
            this.data = data;
            let mlist = [];

            if (this.data) {
                console.log('there is data' +  data);

                data = JSON.parse(data);
                
                data.forEach(function(element){
                     
                    mlist.push({label: element.makeName, value: element.makeId});
                    
                });
                
            } else if (error) {
                 
                this.loading=false;
                this.showToast('Something went wrong', error.body.message, 'error');
                return;
                
            }
            this.makelist =mlist;
            this.loading = false;
            
    }

    /***********************************************************************************************************
    * getAssetTypes
    ************************************************************************************************************/
    @wire(getAssetTypes,{ programId: '$searchProgramId', triggerAssetTypes : '$triggerAssetTypes'}) 
        wiredgetAssetTypes({ error, data }) {
            
            this.loading=true;

            console.log('in getAssetTypes' + this.searchProgramId);
            
            this.data = data;
            let alist = [];

            if (this.data) {
                console.log('there is data' +  data);

                data = JSON.parse(data);
                
                data.forEach(function(element){

                    //if (element.assetTypeName != 'Forklift Accessories')
                     
                        alist.push({label: element.assetTypeName, value: element.assetTypeId});
                    
                });
                
            } else if (error) {
                 
                this.loading=false;
                this.showToast('Something went wrong', error.body.message, 'error');
                return;
                
            }
             
            this.assettypelist = alist;
            this.loading = false;

             
            
    }

    /***********************************************************************************************************
    * getAssets is getModels
    ************************************************************************************************************/
    @wire(getModels,{  programId: '$searchProgramId', make: '$searchMake', assetType: '$searchAssetType'}) 
        wiredgetModels({ error, data }) {
            
            this.loading=true; 

            console.log('in getModels' + this.searchProgramId + this.searchMake + this.searchAssetType);
            
            let mlist = [];

            if (this.data) {
                console.log('there is data' +  data);

                data = JSON.parse(data);
                
                data.forEach(function(element){
                     
                    mlist.push({label: element.modelName, value: element.modelId});
                    
                });
                
            } else if (error) {
                 
                this.loading=false;
                this.showToast('Something went wrong', error.body.message, 'error');
                return;
                
            }
             
            this.modellist =mlist;
            this.loading = false;
            
    }

    /***********************************************************************************************************
    * getAccessories
    ************************************************************************************************************/
    @wire(getAccessories,{  programId: '$searchProgramId', make: '$searchMake'}) 
        wiredgetAccessories({ error, data }) {
            
            this.loading=true; 

            console.log('in get accessories' + this.searchMake);
             
            let acclist = [];

            if (data) {
                console.log('there is data' +  data);

                data = JSON.parse(data);
                
                data.forEach(function(element){
                     
                    acclist.push({label: element.modelName, value: element.modelId});
                    
                });
                
            } else if (error) {
                 
                this.loading=false;
                this.showToast('Something went wrong', error.body.message, 'error');
                return;
                
            }
            this.accessorylist =acclist;
            this.loading = false;
            
    }

 /***********************************************************************************************************
    * getAsset 
    ************************************************************************************************************/
    @wire(getAsset,{  programId: '$searchProgramId', assetId: '$searchAssetId'}) 
        wiredgetAsset({ error, data }) {
            
            this.loading=true;

            console.log('in getAsset');
            
            this.data = data;
            let elist = [];            
            let hlist = [];
            let mlist = [];
            let blist = [];

            if (this.data) {
                console.log('there is data' + JSON.stringify(data));

                let obj = JSON.parse(data);

                var om =  obj["data"]["finance"]["residualValue"]["adjustments"]["mastType"]; 
                if (om != null){
                    for (let i = 0; i < om.length; i++) {

                        let lab = obj["data"]["finance"]["residualValue"]["adjustments"]["mastType"][i];
                        let val =obj["data"]["finance"]["residualValue"]["adjustments"]["mastType"][i];
                        console.log('label:' + lab + ' ' + 'value: ' + val) ;
      
      	                mlist.push({label: lab, value: val});
                    } 
                } 

                var oe = obj["data"]["finance"]["residualValue"]["adjustments"]["operatingEnvironment"];			
             
                if (oe != null){
                    for (let i = 0; i < oe.length; i++) {

                        let lab = obj["data"]["finance"]["residualValue"]["adjustments"]["operatingEnvironment"][i];
                        let val= obj["data"]["finance"]["residualValue"]["adjustments"]["operatingEnvironment"][i];
                        console.log('label:' + lab + ' ' + 'value: ' + val) ;
      
      	                elist.push({label: lab, value: val});
                    }
                }  

                var oh = obj["data"]["finance"]["residualValue"]["adjustments"]["operatingHoursPerYear"];			
                 
                if (oh != null){
                    for (let i = 0; i < oh.length; i++) {

                        let lab = obj["data"]["finance"]["residualValue"]["adjustments"]["operatingHoursPerYear"][i];
                        let val= obj["data"]["finance"]["residualValue"]["adjustments"]["operatingHoursPerYear"][i];
                        console.log('label:' + lab + ' ' + 'value: ' + val) ;
      
      	                hlist.push({label: lab, value: val});
                    } 
                } 

                var oh = obj["data"]["finance"]["residualValue"]["adjustments"]["industrialBattery"];			
             
                if (oh != null){
                    for (let i = 0; i < oh.length; i++) {

                        let lab = obj["data"]["finance"]["residualValue"]["adjustments"]["industrialBattery"][i];
                        let val= obj["data"]["finance"]["residualValue"]["adjustments"]["industrialBattery"][i];
                        console.log('label:' + lab + ' ' + 'value: ' + val) ;
      
      	                blist.push({label: lab, value: val});
                    } 
                } 
                 
            } else if (error) {
                 
                this.loading=false;
                this.showToast('Something went wrong', error.body.message, 'error');
                return;
                
            }
            this.environmentlist = elist;
            this.hourlist = hlist;
            this.mastlist = mlist;
            this.batterylist = blist;
            this.loading = false;
            
    }


    //handles...

    submitCredit(event) {
        console.log('before credit');

        let price = 0; 

        this.loading = true;

        console.log (this.userSite + ' ' + this.programId);
        submitCreditApp({quoteId : '0Q0040000000Y9PCAU'})
            .then(result => {
                this.loading = false;
                console.log('response: ' + result);
                let obj = JSON.parse(result);
                console.log(obj);
                console.log(obj.data.id);
                this.creditresponse = 'ID: ' +  obj.data.id + ' Status: ' + obj.data.status;
                 
                this.loading = false;

                  
            })
            .catch(error => {
                this.error = error;
                this.loading=false;
                this.showToast('Something went wrong', error.body.message, 'error');
                return;
            });

        console.log('after credit');

        
    }

    submitCreditPreQual(event) {
        console.log('before credit  2');

        let price = 0; 

        this.loading = true;

        console.log ('opp is: ' + ' ' + '006780000034QtFAAU');
        submitPreQualCreditApp({opportunityId : '006780000034QtFAAU'})
            .then(result => {
                this.loading = false;
                console.log('response: ' + result);
                let obj = JSON.parse(result);
                console.log('obj is: ' + obj);
                this.creditresponsepq = 'ID: ' +  obj.data.id + ' Status: ' + obj.data.status;
                this.loading = false;
            })
            .catch(error => {
                this.error = error;
                this.loading=false;
                this.showToast('Something went wrong', error.body.message, 'error');
                return;
            });

        console.log('after credit');

        
    }

    handleAccountName(event) {
        this.strSearchAccName = event.detail.value; 
    }

    calcPricing(event) {

        let price = 0; 

        this.loading = true;

        console.log (this.userSite + ' ' + this.programId);
        getPrice({quoteId : '0Q0040000000WeTCAU', siteId : this.userSite, programId : this.programId})
            .then(result => {
                this.loading = false;
                let obj = JSON.parse(result);
                this.monthlyprice =  obj.paymentAmount;
                this.loading = false;
            })
            .catch(error => {
                this.error = error;
                this.loading=false;
                this.showToast('Something went wrong', error.body.message, 'error');
                return;
            });

        console.log('after calcpricing');

        
    }

    handleSearch() {

        if(!this.strSearchAccName) {
            this.errorMsg = 'Please enter account name to search.';
            this.searchData = undefined;
            return;
        }
        
        
        quickSearch({strAccName : this.strSearchAccName, city : null})
        .then(result => {
            
            result = JSON.parse(result);
            console.log('result is: ' + result);
            let searchResults = [];
        
            result.forEach(record => {
                let preparedCustomer = {}; 
                //BillingStreet, BillingState, BillingPostalCode, BillingCity, BillingAddress, Name
                preparedCustomer.Id = record.Id;
                preparedCustomer.Name = record.Name +  ' : ' + record.BillingStreet + ' ' + record.BillingCity + ', ' + record.BillingState + ' ' + record.BillingPostalCode;
                searchResults.push(preparedCustomer);
            });

            if (this.searchData){
                
                this.searchData = searchResults;
                console.log('search data is: ' + JSON.stringify(this.searchData));
                this.loadMoreStatus = 'Search complete!';
            }
            
        })
        .catch(error => {
            this.searchData = undefined;
            window.console.log('error =====> '+JSON.stringify(error));
            if(error) {
                this.errorMsg = error.body.message;
            }
        }) 
    }

    searchHandler(event) {
        
        this.searchCustomer = event.detail.value;
        
        if (event.keyCode == 9 || event.keyCode == 13){
            this.loading = true;
        }
        else{ 
            quickSearch({name : this.searchCustomer, city : null})
                .then(result => {
                    this.loading = false;
                    let data = JSON.parse(result);
                    let slist = [];
                    data.forEach(function(element){
                        console.log(element.Name);
                        slist.push({label: element.Name, value: element.Id});
                    });
                    this.searchresultlist = slist;
                })
                .catch(error => {
                    this.error = error;
                    this.loading=false;
                    this.showToast('Something went wrong', error.body.message, 'error');
                    return;
                });

        }
        
    }
   
     

    handleChange(event) {
        console.log('in change1');
        this.program = event.detail.value;
        this.searchSiteName = this.userSite;
        this.searchProgramId = this.program;
        let text = this.program;
        let index = text.lastIndexOf('.');
        this.programId = text.substr(index+1,text.length);
        
        this.loading = true;
    }

    handleChange2(event) {
        console.log('in change2' + event.detail.value);
        this.assettypelist = [];
        this.make = event.detail.value
        this.searchMake = this.make;
        this.makelabel = event.target.options.find(opt => opt.value === event.detail.value).label;
        console.log('make label is: ' + this.makelabel);
         
        this.triggerAssetTypes = this.make;
         
        this.loading=true;
         
    }

    handleChange3(event) {
        console.log('in change3');
        
        this.assettypeid = event.detail.value;
    
        this.searchAssetType = this.assettypeid;
        this.loading=true;
    }

    handleChangeAcc(event) {
        console.log('in change acc');
        this.accessoryId = event.detail.value;
        this.loading=false;
    }


    handleChangeSite(event) {
        console.log('in change site');
        this.site = event.detail.value;
        this.userSite = this.site;

        this.getSalesReps(event);
        
        this.loading=true;
    } 

    handleChangeSalesRep(event){
         
        this.salesrepid =  event.detail.value;;
    
    }


    handleChange4(event) {
    
        this.assetId = event.detail.value;
        this.searchAssetId = this.assetId;
        this.modellabel = event.target.options.find(opt => opt.value === event.detail.value).label;
     
        this.loading=true;

    }

    handleChange5(event) {
        console.log('in change5');
        this.mast = event.detail.value;
        
    }

    handleChange6(event) {
        console.log('in change6');
        this.hours= event.detail.value;
        this.loading=false;
    }

    handleChange7(event) {
        console.log('in change7');
        this.environment= event.detail.value;
    }

    handleChange8(event) {
        console.log('in change8');
        this.battery= event.detail.value;
         
    }

    handleChange9(event) {
        console.log('in change9');
        this.subsidylist = [];
        this.term= event.detail.value;

        this.getSubsidies(event);
         
    }

    handleChange10(event) {
        console.log('in change10');
        this.advance= event.detail.value;
         
    }

    handleChange11(event) {
        console.log('in change11');
        this.financetype= event.detail.value;
        console.log('financetype=' + this.financetype);
        this.searchFinanceType = this.financetype;
         
    }

    handleChange12(event) {
        console.log('in change12');
        this.frequency= event.detail.value;
         
    }

    handleChange13(event) {
        console.log('in change13');
    
        this.financialproduct = event.detail.value;
     
    
    }

    handleChange14(event) {
         
        console.log('in change14');
        this.searchName = event.detail.value;
    
        this.searchHandler(event);
     
         
    }

    handleChangeSub(event) {
         
        console.log('in change sub');

        this.subsidyId = event.detail.value;
    
     
         
    }

    handleChildSave(event){
        console.log('parent got the word');
    }

    handleProgress(event) {
        console.log('event: ' + event.detail);
        window.location.reload();
    }


}