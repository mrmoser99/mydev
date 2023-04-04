/************************************************************************************************************
*
*  Change Log:
*   01/25/2023 - MRM - added mode as an api;
*   02/20/2023 - MRM -added isPortalUser for navigation
    02/24/2023 - PBI 902314 - Vinicio Ramos Silva - As a portal user I should get a confirmation message when I try to delete a quote from the quote list view
    03/07/2023 - PBI 902314 - Vinicio Ramos Silva - change in confirmation text to delete record
    03/22/2023 - PBI 943211 - Vinicio Ramos Silva - Application Listview Download functionality for Quote & Portfolio
*************************************************************************************************************/
import {LightningElement,track, wire,api} from 'lwc';

import {checkPermission} from 'c/dodJSUtility';

import getQuotes from '@salesforce/apex/QuoteListView.getQuotes';
import getQuotesNum from '@salesforce/apex/QuoteListView.getQuotesNum';
import deleteOpp from '@salesforce/apex/QuoteListView.deleteOpp';
import {getObjectInfo,getPicklistValues} from "lightning/uiObjectInfoApi";
import OPPORTUNITY_OBJECT from '@salesforce/schema/Opportunity';
import STATUS_FIELD from "@salesforce/schema/Opportunity.Sub_Stage__c";
import {NavigationMixin} from 'lightning/navigation';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import {getPicklistValuesByRecordType} from 'lightning/uiObjectInfoApi';
import LightningConfirm from "lightning/confirm";
import LightningAlert from "lightning/alert";
import IsPortalEnabled from "@salesforce/apex/PricingUtils.isPortalEnabled";


const columns = [{
        label: 'Quote Number',
        fieldName: 'QuoteNumberURL',
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: {
                fieldName: 'Qnumber'
            },
            target: '_self'
        }
    },
    // Start PBI - 902314
    {
        label: 'Application Number',
        fieldName: 'applicationNumber',
        type: 'text',
        sortable: true
    }, 
    // End PBI - 902314   
    {
        label: 'Customer',
        fieldName: 'EndUserURL',
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: {
                fieldName: 'endUserName'
            },
            target: '_self'
        }
    },
    {
        label: 'Creator',
        fieldName: 'createdbyname',
        type: 'text',
        sortable: true,
        typeAttributes: {
            label: {
                fieldName: 'CreatedBy.Name'
            }
        }
    },
    {
        label: 'Nickname',
        fieldName: 'nickName',
        type: 'text',
        sortable: true,
        fixedWidth: 110
    },
    {
        label: 'Sales Rep',
        fieldName: 'SalesRepValue',
        type: 'text',
        sortable: true
    },
    {
        label: 'Date Created',
        fieldName: 'CreatedDate',
        type: 'date-local',
        typeAttributes: {
            month: "2-digit",
            day: "2-digit"
        },
        sortable: true,
        fixedWidth: 110
    },
    {
        label: 'Last Modified',
        fieldName: 'lastModifiedDate',
        type: 'date-local',
        typeAttributes: {
            month: "2-digit",
            day: "2-digit"
        },
        sortable: true,
        fixedWidth: 110
    },
    {
        label: 'Status',
        fieldName: 'substage',
        type: 'text',
        sortable: true,
        fixedWidth: 150
    }
    
];

export default class quoteListView extends NavigationMixin(LightningElement) {


    //API
    @api mode;

    regularMode = true;

    ccMode = false;

    //Declare @tracks
    @track quotes = [];
    @track totalNumberOfRows;
    @track loader = false;

    //Button/Link Permissions
    NQ01 = false;
    isPortalUser = false;
    //Declare properties
    error;
    columns = columns;
    sortBy;
    sortDirection;
    rowLimit = 20;
    rowOffset = 0;
    loadMoreStatus;
    applicationDate = '';
    applicationDatePickListValues = [];    
    @track partnerStatus='';
    @track salesRepFilter = '';
    @track allValues = [];
    partnerStatusPickListValues = [
        {   label: 'All', value: ''},
        {   label: 'Application Draft', value: 'Application Draft'},
        {   label: 'Application Submitted', value: 'Application Submitted'},
        {   label: 'Quote Draft', value: 'Quote Draft'},
        {   label: 'Quoting & Proposal', value: 'Quoting & Proposal'}
    ];
    partnerStatusPickListValuesCCMode = [
        {   label: 'All', value: ''},
        {   label: 'Application Draft', value: 'Application Draft'},
        {   label: 'Quote Draft', value: 'Quote Draft'},
        {   label: 'Quoting & Proposal', value: 'Quoting & Proposal'}
    ];
    searchAllValue = '';
    enableInfiniteLoading = true;
    initialDataLoaded = false;
    datatable;
    itemCount;
    now = Date.now();
    saleRapOptions;
    saleRapValue = '';
    errorMsg = '';
    tempOpportunitiesList = [];
    
    constructor() {
        super();
        this.columns = this.columns.concat( [
            { type: 'action', typeAttributes: { rowActions: this.getRowActions } }
        ] );
    }
    
    //wire Opportunity Object
    @wire(getObjectInfo, {
        objectApiName: OPPORTUNITY_OBJECT
    })
    objectInfo;

    //Display toast
    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'dismissible'
        });
        this.dispatchEvent(event);
    }

    //method to check if the permission is true or false; this drives display of the button or link
    async setPermissions() {

        this.NQ01 = await checkPermission('NQ01'); 
        
    }

    //calling connectedCallback
    connectedCallback() {

        console.log('mode is: ' + this.mode);

        if (this.mode == 'cc'){
            this.ccMode = true;
            this.regularMode = false;
        }else{
            this.ccMode = false;   
            this.regularMode = true;
        }

        this.setPermissions();
        
        let thisYearNum = new Date().getFullYear();
        let thisYear = thisYearNum.toString();
        let lastYearNum = thisYear - 1;
        let lastYear = lastYearNum.toString();
        let lastTwoYearNum = thisYear - 2;
        let lastTwoYear = lastTwoYearNum.toString();
        let lastThreeYearNum = thisYear - 3;
        let lastThreeYear = lastThreeYearNum.toString();
        let lastFourYearNum = thisYear - 4;
        let lastFourYear = lastFourYearNum.toString();
        this.applicationDatePickListValues.push({
            label: 'All Time',
            value: ''
        }, {
            label: 'Last 30 days',
            value: '30D'
        }, {
            label: 'Last 60 days',
            value: '60D'
        }, {
            label: 'Last 6 months',
            value: '6M'
        }, {
            label: 'Last 12 months',
            value: '12M'
        }, {
            label: thisYear,
            value: thisYear
        }, {
            label: lastYear,
            value: lastYear
        }, {
            label: lastTwoYear,
            value: lastTwoYear
        }, {
            label: lastThreeYear,
            value: lastThreeYear
        }, {
            label: lastFourYear,
            value: lastFourYear
        });

        IsPortalEnabled().then(result => {
            console.log('result is : ' + result);
            this.isPortalUser = result;
        });

        //load data
        this.getInitialOpportunities();
    }

    //method to load data
    getInitialOpportunities() {
        //apex call to get Quotes
        
        getQuotes({
                rowLimit: this.rowLimit,
                rowOffset: this.rowOffset,
                submittedDate: this.applicationDate,
                partnerStatus: this.allValues,
                searchAllValue: this.searchAllValue,
                sortBy: this.sortBy,
                sortDirection: this.sortDirection,
                ccMode : this.ccMode,
                salesRepFilter: this.salesRepFilter
            }).then(result => {
                //on success 
                if (result) {                    
                    let tempOpportunitiesList = [];
                    result.forEach((record) => {
                        let tempOpportunity = Object.assign({}, record);

                        //create temp variable createdbyname
                        if (tempOpportunity.Opportunity.CreatedBy.Name != null) {
                            tempOpportunity.createdbyname = tempOpportunity.Opportunity.CreatedBy.FirstName + ' ' + tempOpportunity.Opportunity.CreatedBy.LastName;
                        }
                        // Start PBI - 902314    
                        //create temp variable Application Number
                        if (tempOpportunity.Opportunity.Application_Number__c != undefined) {
                            tempOpportunity.applicationNumber = tempOpportunity.Opportunity.Application_Number__c;
                        }
                        // End PBI - 902314        
                        //create temp variable QuoteNumberURL
                        if (tempOpportunity.Opportunity.Opportunity_Number__c == undefined) {
                            tempOpportunity.QuoteNumberURL = '#';
                            tempOpportunity.Qnumber = '#';
                        } else {
                            
                            console.log('this is portal user = ' + this.isPortalUser);
                            if (!this.isPortalUser){
                                tempOpportunity.QuoteNumberURL = window.location.origin + '/lightning/n/Quote?c__oppid=' + tempOpportunity.Opportunity.Id;
                                tempOpportunity.Qnumber = tempOpportunity.Opportunity.Opportunity_Number__c;
                            }
                            else{
                                tempOpportunity.QuoteNumberURL = window.location.origin + '/dllondemand/s/new-quote?oppid=' + tempOpportunity.Opportunity.Id;
                                tempOpportunity.Qnumber = tempOpportunity.Opportunity.Opportunity_Number__c;
                            }
                        }
                        //create temp variable endUserName
                        if (tempOpportunity.Opportunity.End_User__r) {
                            console.log('enduser name ' + tempOpportunity.Opportunity.End_User__r.Name);
                            tempOpportunity.endUserName = tempOpportunity.Opportunity.End_User__r.Name;
                        } else {
                            tempOpportunity.endUserName = 'Unknown';
                        }

                          //Start: Bug 879195 - Sales Rep  values not getting populated in the list views
                          if (tempOpportunity.Partner_Sales_Rep__r) {
                            console.log('Sales Rep ' + tempOpportunity.Partner_Sales_Rep__r.name);
                            tempOpportunity.SalesRepValue = tempOpportunity.Partner_Sales_Rep__r.Name;
                        } else {
                            tempOpportunity.SalesRepValue = '';
                        }
                        //END: Bug 879195 - Sales Rep  values not getting populated in the list views
                        
                        //create temp variable nickName
                        if (tempOpportunity.Opportunity.Nickname__c) {
                            tempOpportunity.nickName = tempOpportunity.Opportunity.Nickname__c;
                        } else {
                            tempOpportunity.nickName = 'Unknown';
                        }

                        //create temp variable CreatedDate
                        if (tempOpportunity.Opportunity.CreatedDate) {
                        tempOpportunity.CreatedDate = tempOpportunity.Opportunity.CreatedDate;
                        } else {
                        tempOpportunity.CreatedDate = 'Unknown';
                        }


                        //create temp variable LastModifiedDate
                        if (tempOpportunity.Opportunity.LastModifiedDate) {
                        tempOpportunity.lastModifiedDate = tempOpportunity.Opportunity.LastModifiedDate;
                        } else {
                        tempOpportunity.lastModifiedDate = 'Unknown';
                        }  

                    
                        //create temp variable substage
                        if (tempOpportunity.Opportunity.Sub_Stage__c) {
                        tempOpportunity.substage = tempOpportunity.Opportunity.Sub_Stage__c;
                        } else {
                        tempOpportunity.substage = 'Unknown';
                        }  
                        
                        //create temp variable EndUserURL
                        if (tempOpportunity.Opportunity.End_User__c == undefined) {
                            tempOpportunity.EndUserURL = '#';
                        } else {
                            if (this.isPortalUser){
                                tempOpportunity.EndUserURL = window.location.origin + '/dllondemand/s/account/' + tempOpportunity.Opportunity.End_User__c;
                            }
                            else
                                tempOpportunity.EndUserURL = window.location.origin + '/lightning/r/Account/' + tempOpportunity.Opportunity.End_User__c + '/view';
                        }

                        tempOpportunitiesList.push(tempOpportunity);

                    });

                    this.quotes = tempOpportunitiesList;

                    //get Quote Count
                    getQuotesNum({
                            rowLimit: this.rowLimit,
                            rowOffset: this.rowOffset,
                            submittedDate: this.applicationDate,
                            partnerStatus: this.allValues,
                            searchAllValue: this.searchAllValue,
                            ccMode : this.ccMode,
                            salesRepFilter: this.salesRepFilter
                        }).then(result => {
                            //On success
                            if (result) {

                                this.totalNumberOfRows = result;
                                this.initialDataLoaded = true;
                                if (this.totalNumberOfRows > this.rowLimit) {
                                    this.itemCount = this.rowLimit + '+';
                                } else {
                                    this.itemCount = this.totalNumberOfRows;
                                }
                            }

                        })
                        //Handle error
                        .catch(err => {
                            console.log('Error in QuoteListView = ' + JSON.stringify(err));
                        })
                } else {
                    this.initialDataLoaded = true;
                    console.error("No Data - QuoteListView is null");
                }
            })
            //Handle error
            .catch(err => {
                console.log('Error in QuoteListView = ' + JSON.stringify(err));
            })
    }

    getRowActions(row, doneCallback) {
    const actions = [];
        if (row.applicationNumber == undefined) {
            actions.push(
                {
                    label: 'Delete',
                    name: 'delete'
                }, {
                    label: 'Edit',
                    name: 'edit'
                }
            );
        } else {
            actions.push(
                {
                    label: 'Edit',
                    name: 'edit'
                }
            );
        }
        // simulate a trip to the server
        setTimeout(() => {
            doneCallback(actions);
        }, 200);           
    }
    

    // Event to handle onloadmore on lightning datatable 
    loadMoreData(event) {
        event.preventDefault();

        this.datatable = event.target;
        if (this.initialDataLoaded) {
            this.enableInfiniteLoading = true;
            this.datatable.isLoading = true;
            this.loadMoreStatus = 'Loading';
            this.rowOffset = this.rowLimit + this.rowOffset;

            if (this.rowOffset <= this.totalNumberOfRows) {

                //getQuotes
                getQuotes({
                        rowLimit: this.rowLimit,
                        rowOffset: this.rowOffset,
                        submittedDate: this.applicationDate,
                        partnerStatus: this.allValues,
                        searchAllValue: this.searchAllValue,
                        sortBy: this.sortBy,
                        sortDirection: this.sortDirection,
                        salesRepFilter: this.salesRepFilter
                    }).then(result => {
                        //On success
                        let tempMoreOpportunitiesList = [];

                        result.forEach((record) => {
                            let tempMoreOpportunity = Object.assign({}, record);
                          /*  tempMoreOpportunity.EndUserURL = window.location.origin + '/dllondemand/s/account/' + tempMoreOpportunity.Opportunity.End_User__c;
                            tempMoreOpportunity.QuoteNumberURL = window.location.origin + '/dllondemand/s/new-quote?oppid=' + tempMoreOpportunity.Opportunity.Id;

                            if (tempMoreOpportunity.Opportunity.CreatedBy.Name != null) {
                                tempMoreOpportunity.createdbyname = tempMoreOpportunity.Opportunity.CreatedBy.FirstName + ' ' + tempMoreOpportunity.Opportunity.CreatedBy.LastName;
                            }

                            if (tempMoreOpportunity.Opportunity.End_User__r) {
                                console.log('enduser name ' + tempMoreOpportunity.Opportunity.End_User__r.Name);
                                tempMoreOpportunity.endUserName = tempMoreOpportunity.Opportunity.End_User__r.Name;
                            } else {
                                tempMoreOpportunity.endUserName = 'Unknown';
                            }*/

                            //new code. Old code commented above
                              //create temp variable createdbyname
                        if (tempMoreOpportunity.Opportunity.CreatedBy.Name != null) {
                            tempMoreOpportunity.createdbyname = tempMoreOpportunity.Opportunity.CreatedBy.FirstName + ' ' + tempMoreOpportunity.Opportunity.CreatedBy.LastName;
                        }
                        // Start PBI - 902314    
                        //create temp variable Application Number
                        if (tempMoreOpportunity.Opportunity.Application_Number__c != undefined) {
                            tempMoreOpportunity.applicationNumber = tempMoreOpportunity.Opportunity.Application_Number__c;
                        }
                        // End PBI - 902314 
                        //create temp variable QuoteNumberURL
                        if (tempMoreOpportunity.Opportunity.Opportunity_Number__c == undefined) {
                            tempMoreOpportunity.QuoteNumberURL = '#';
                            tempMoreOpportunity.Qnumber = '#';
                        } else {
                            tempMoreOpportunity.QuoteNumberURL = window.location.origin + '/dllondemand/s/new-quote?oppid=' + tempMoreOpportunity.Opportunity.Id;
                            tempMoreOpportunity.Qnumber = tempMoreOpportunity.Opportunity.Opportunity_Number__c;
                        }
                        //create temp variable endUserName
                        if (tempMoreOpportunity.Opportunity.End_User__r) {
                            console.log('enduser name ' + tempMoreOpportunity.Opportunity.End_User__r.Name);
                            tempMoreOpportunity.endUserName = tempMoreOpportunity.Opportunity.End_User__r.Name;
                        } else {
                            tempMoreOpportunity.endUserName = 'Unknown';
                        }

                        //Start: Bug 879195 - Sales Rep  values not getting populated in the list views
                        if (tempMoreOpportunity.Opportunity.Partner_Sales_Rep__r) {
                            console.log('Sales Rep ' + tempMoreOpportunity.Opportunity.Partner_Sales_Rep__r.name);
                            tempMoreOpportunity.SalesRepValue = tempMoreOpportunity.Opportunity.Partner_Sales_Rep__r.Name;
                        } else {
                            tempMoreOpportunity.SalesRepValue = '';
                        }
                        //End: Bug 879195 - Sales Rep  values not getting populated in the list views


                        //create temp variable nickName
                        if (tempMoreOpportunity.Opportunity.Nickname__c) {
                            tempMoreOpportunity.nickName = tempMoreOpportunity.Opportunity.Nickname__c;
                        } else {
                            tempMoreOpportunity.nickName = 'Unknown';
                        }

                        //create temp variable CreatedDate
                        if (tempMoreOpportunity.Opportunity.CreatedDate) {
                            tempMoreOpportunity.CreatedDate = tempMoreOpportunity.Opportunity.CreatedDate;
                        } else {
                            tempMoreOpportunity.CreatedDate = 'Unknown';
                        }


                        //create temp variable LastModifiedDate
                        if (tempMoreOpportunity.Opportunity.LastModifiedDate) {
                            tempMoreOpportunity.lastModifiedDate = tempMoreOpportunity.Opportunity.LastModifiedDate;
                        } else {
                            tempMoreOpportunity.lastModifiedDate = 'Unknown';
                        }  

                    
                        //create temp variable substage
                        if (tempMoreOpportunity.Opportunity.Sub_Stage__c) {
                            tempMoreOpportunity.substage = tempMoreOpportunity.Opportunity.Sub_Stage__c;
                        } else {
                            tempMoreOpportunity.substage = 'Unknown';
                        }  
                        
                        //create temp variable EndUserURL
                        if (tempMoreOpportunity.Opportunity.End_User__c == undefined) {
                            tempMoreOpportunity.EndUserURL = '#';
                        } else {
                            tempMoreOpportunity.EndUserURL = window.location.origin + '/dllondemand/s/account/' + tempMoreOpportunity.Opportunity.End_User__c;
                        }


                            tempMoreOpportunitiesList.push(tempMoreOpportunity);

                        });

                        this.quotes = this.quotes.concat(tempMoreOpportunitiesList);
                        this.loadMoreStatus = '';
                        this.datatable.isLoading = false;
                        this.itemCount = this.rowOffset + '+';
                    })
                    //Handle error
                    .catch(err => {
                        console.log('Error in QuoteListView = ' + JSON.stringify(err));
                    })
            } else {
                this.enableInfiniteLoading = false;
                this.datatable.isLoading = false;
                this.loadMoreStatus = 'No more data to load';
                this.itemCount = this.totalNumberOfRows;
            }
        }
    }

    // The method onsort event handler
    updateColumnSorting(event) {
        // assign the latest attribute with the sorted column fieldName and sorted direction
        this.sortBy = event.detail.fieldName;
        this.sortDirection = event.detail.sortDirection;
        this.enableInfiniteLoading = true;
        this.isLoading = true;
        this.quotes = [];
        this.rowOffset = 0;
        //load data
        this.getInitialOpportunities();
    }

    //Method to handle date change
    handleChangeDate(event) {
        //get application date change
        this.applicationDate = event.target.value;
        this.enableInfiniteLoading = true;
        this.isLoading = true;
        this.quotes = [];
        this.rowOffset = 0;
        //load data
        this.getInitialOpportunities();
    }

    //Method to handle status change
    handleChangeStatus(event) {
        
        console.log('entrou status');
        console.log('entrou event.target.value   '+ event.target.value);
        if(event.target.value == ''){
            this.allValues = [];
            this.partnerStatus=''; 
        }
        else{
            if(!this.allValues.includes(event.target.value)){           
                this.allValues.push(event.target.value); 
            }                
        }       
        this.partnerStatus = event.target.value;
        this.enableInfiniteLoading = true;
        this.isLoading =true;
        this.opportunities = [];
        this.rowOffset = 0;
        this.getInitialOpportunities();
    }

    handleChangeSalesRep(event) {
        this.salesRepFilter = event.target.value;
        clearTimeout(this.debounceTimeout);
        this.debounceTimeout = setTimeout(() => {
            this.enableInfiniteLoading = true;
            this.isLoading =true;
            this.opportunities = [];
            this.rowOffset = 0;
            this.getInitialOpportunities();
         }, 2000);
        
    }

    handleRemove(event){
        
        const valueRemoved = event.target.name;
        this.allValues.splice(this.allValues.indexOf(valueRemoved),1);
        //this.sortBy='Application_Date__c';
        this.sortDirection='desc';
        this.loadMoreStatus = '';
        this.initialDataLoaded = false;
        this.rowOffset = 0;
        this.enableInfiniteLoading = true;
        this.isLoading =true;
        this.opportunities = [];
        this.getInitialOpportunities();
    }

    handleClearFilters(event){
        this.allValues = [];
        this.partnerStatus='';
        this.applicationDate='';
        this.salesRepFilter='';
        //this.sortBy='Application_Date__c';
        this.sortDirection='desc';
        this.loadMoreStatus = '';
        this.initialDataLoaded = false;
        this.rowOffset = 0;
        this.enableInfiniteLoading = true;
        this.isLoading =true;
        this.opportunities = [];
        
        this.getInitialOpportunities();
    }




    //Method to handle KeyPress on search
    handleKeyUp(event) {
        const isEnterKey = event.keyCode === 13;
        if (isEnterKey) {
            this.searchAllValue = event.target.value.trim();
            this.enableInfiniteLoading = true;
            this.isLoading = true;
            this.quotes = [];
            this.rowOffset = 0;
            //load data
            this.getInitialOpportunities();
        }
    }

    //Method to reset Quote List
    resetList(event) {
        if (event.detail.value) {
            return;
        } else {
            this.searchAllValue = '';
            this.enableInfiniteLoading = true;
            this.isLoading = true;
            this.quotes = [];
            this.rowOffset = 0;
            //load data
            this.getInitialOpportunities();
        }
    }
    //Method for future implementation
    //***Start*/
    onSalesRepChange(event) {
        if (event.detail.value == undefined || event.detail.value == '' || event.detail.value == null) {
            this.errorMsg = event.detail;
            this.quotes = this.tempOpportunitiesList;
        } else {
            this.errorMsg = '';
            this.saleRapValue = event.detail.value;
            const quoteListForFilter = [];
            for (var key in this.tempOpportunitiesList) {
                if (this.tempOpportunitiesList[key].Opportunity.Sales_Rep_Name__c == this.saleRapValue) {
                    quoteListForFilter.push(this.tempOpportunitiesList[key]);
                }

            }
            this.initialDataLoaded = false;
            this.quotes = quoteListForFilter;
        }

    }
    /***End*/

    //Method to handle create quote button
    createQuoteButton() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                //call new quote page
                url: window.location.origin + '/dllondemand/s/new-quote'
            }
        });
    }

    //Method to handle Row action event - edit and delete
    handleRowAction(event) {

        this.loader = true;
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        console.log('what is the action man:' + actionName);

        if (actionName === 'delete') {
            console.log('delete row.OpportunityId:' + row.OpportunityId);
            console.log('delete row applicationNumber:' + row.applicationNumber);
            this.handleConfirmClick(row);            
        }
        
        if (actionName === 'edit') {
            this.loader = false;
            this[NavigationMixin.Navigate]({
                type: 'standard__webPage',
                attributes: {
                    url: window.location.origin + '/dllondemand/s/new-quote?oppid=' + row.OpportunityId
                }
            });
        }
        console.log('what is the action man:' + actionName);        
    }
        
    async handleConfirmClick(row) {
        const result = await LightningConfirm.open({
            message: "You are about to delete the record. If you clicked \"Delete\" by accident, select Cancel.",
            variant: "default", // headerless
            label: "Are you sure, you want to delete the record?"
        });
        //Confirm has been closed        
        //result is true if OK was clicked
        if (result) {
            deleteOpp({
                oppId: row.OpportunityId
            }).then(result => {

                this.loader = false;
                this.getInitialOpportunities();
                this.showToast('Quote deleted Successfully', result, 'success');

            }).catch(error => {
                console.log('error' + JSON.stringify(error));
                this.loader = false;
            })
            
        } else {
            this.loader = false;
        }
    }
    
    handleSelectQuote(event){

        console.log('dispatching childselect event');

        var el = this.template.querySelector('lightning-datatable');
        console.log(el);
        var selected = el.getSelectedRows();
        console.log('selected is: ' + selected);
         

        if (selected == '') {
            const evt = new ShowToastEvent({
                            title:      'Error',
                            message:    'A quote must be selectred!',
                            variant:    'error',
                            duration:   20000
                            });
                        this.dispatchEvent(evt);

        }
            

        const passEvent = new CustomEvent('childselect', {
                detail: {quoteNumber: selected[0].Qnumber} 
        });
        this.dispatchEvent(passEvent);

    }

    handleCreateQuote(event){

        console.log('dispatching childcreate event');

        const passEvent = new CustomEvent('childcreate', {
                detail: {quoteNumber: 'New Option'} 
            });
        this.dispatchEvent(passEvent);

    }

    handleCancel(event){

            const passEvent = new CustomEvent('childcancel', {
            });
            this.dispatchEvent(passEvent);

    }


    //Start PBI 943211 - Vinicio Ramos Silva - Application Listview Download functionality for Quote & Portfolio
    handleDownload(event) {
        
        getQuotes({

            rowLimit: 9999,
            rowOffset: 0,
            submittedDate: this.applicationDate,
            partnerStatus: this.allValues,
            searchAllValue: this.searchAllValue,
            sortBy: this.sortBy,
            sortDirection: this.sortDirection,
            ccMode : this.ccMode,
            salesRepFilter: this.salesRepFilter,
            
        }).then(res => {
            const evt = new ShowToastEvent({
               // title: 'Download Quote',
                message: 'Downloading....',
                variant: 'success',
                duration:10000,
            });
            this.dispatchEvent(evt);
            
            
            this.downloaddata= res.map(dt=>{
                let tmp = {...dt};                
                if(!tmp.Opportunity.Opportunity_Number__c) {tmp.Opportunity.Opportunity_Number__c = ' ';}
                if(!tmp.Opportunity.Name) {tmp.Opportunity.Name = ' ';}
                if(!tmp.Opportunity.Application_Number__c) {tmp.Opportunity.Application_Number__c = ' ';}
                if (tmp.Opportunity.End_User__r) {tmp.endUserName = tmp.Opportunity.End_User__r.Name;} 
                else {tmp.endUserName = ' ';} 
                if (tmp.Opportunity.CreatedBy.Name) {tmp.createdbyname = tmp.Opportunity.CreatedBy.FirstName + ' ' + tmp.Opportunity.CreatedBy.LastName;} 
                else {tmp.createdbyname = ' ';} 
                if(!tmp.Nickname__c) {tmp.Nickname__c = ' ';}
                if (tmp.Partner_Sales_Rep__r) {tmp.SalesRepValue = tmp.Partner_Sales_Rep__r.Name;} 
                else {tmp.SalesRepValue = ' ';}
                if(!tmp.Amount__c) {tmp.Amount__c = ' ';}
                if(!tmp.Rate_Type__c) {tmp.Rate_Type__c = ' ';}
                if(!tmp.Total_Payment__c) {tmp.Total_Payment__c = ' ';}
                if(!tmp.Payment_Frequency__c) {tmp.Payment_Frequency__c = ' ';}
                return tmp;
           });     
        
        if(!this.downloaddata || !this.downloaddata.length){
            
            return null
        }
        const jsonObject = JSON.stringify(this.downloaddata);
        const result = this.convertToXLS(jsonObject, this.headers);
        if(result === null) return
        const blob = new Blob([result])
    }) 
    }
    
    convertToXLS(objArray, headers){
        let date = new Date()
        let day = date.getDate();
        let month = date.getMonth()+1;
        let year = date.getFullYear();
        let fullDate = month + "-" + day + "-" + year;
        
        /*added header columns for excel- Download Application*/
        let columnHeader = [
            'Quote Number',
            'Quote Name',
            'Application Number',
            'Customer Name',
            'Creator',
            'Nickname', 
            'Sales Rep',
            'Date Created',
            'Last Modified',
            'Status',
            'Amount',
            'Rate Type',
            'Total Payment',
            'Payment Frequency'
        
        ];
        // Prepare a html table
        let doc = '<style>'; 
        // Add styles for the table
        doc += 'table, th, td {';
        doc += '    border: 1px solid black;';
        doc += '    border-collapse: collapse;';
        doc += '    text-align: left';        
        doc += '}';          
        doc += '</style>';
        
        doc += '<table>';
        
        // Add all the Table Headers
        doc += '<tr>';
        columnHeader.forEach(element => {            
            doc += '<th>'+ element +'</th>'           
        });
        doc += '</tr>';
        // Add the data rows
        const data = typeof objArray !=='object' ? JSON.parse(objArray):objArray
        
        data.forEach(record => {
            doc += '<tr>';
            doc += '<th>'+record.Opportunity.Opportunity_Number__c+'</th>';
            doc += '<th>'+record.Opportunity.Name+'</th>';
            doc += '<th>'+record.Opportunity.Application_Number__c+'</th>';
            doc += '<th>'+record.endUserName+'</th>'; 
            doc += '<th>'+record.createdbyname+'</th>'; 
            doc += '<th>'+record.Opportunity.Nickname__c+'</th>'; 
            doc += '<th>'+record.SalesRepValue+'</th>';  
            doc += '<th>'+new Date(record.Opportunity.CreatedDate).toLocaleDateString()+'</th>';   
            doc += '<th>'+new Date(record.Opportunity.LastModifiedDate).toLocaleDateString()+'</th>';
            doc += '<th>'+record.Opportunity.Sub_Stage__c+'</th>';    
            doc += '<th>'+record.Amount__c+'</th>';   
            doc += '<th>'+record.Rate_Type__c+'</th>';   
            doc += '<th>'+record.Total_Payment__c+'</th>';   
            doc += '<th>'+record.Payment_Frequency__c+'</th>';           
            doc += '</tr>';

        });
        doc += '</table>';
        var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = 'Quotes ' + fullDate +'.xls';
        document.body.appendChild(downloadElement);
        downloadElement.click();
    }    
    //End PBI 943211 - Vinicio Ramos Silva - Application Listview Download functionality for Quote & Portfolio   

}