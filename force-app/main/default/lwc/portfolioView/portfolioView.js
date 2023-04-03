/*********************************************************************************************************
* portfolio view - modified code d05
*
* change log:
*
*   10/18/2021 - MRM created
*   04/28/2022 - Geetha added logic for Download Portfolio and ability to filter records based on 
*                filter criteria
*   03/27/2023 - PBI 943211 - Vinicio Ramos Silva - Application Listview Download functionality for Quote & Portfolio
**********************************************************************************************************/
import { LightningElement, wire, track , api} from 'lwc';
import getRecords from "@salesforce/apex/PortfolioViewController.getRecords";
import getTotalRecords from "@salesforce/apex/PortfolioViewController.getTotalRecords";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import {NavigationMixin} from 'lightning/navigation';

const columns = [
    { label: 'Contract', fieldName: 'contractUrl', wrapText:false, sortable: true, fixedWidth: 160,        type: 'url',
        typeAttributes: {label: { fieldName: 'contractNumber' }, target: '_self'}
    },
    { label: 'Customer Name', fieldName: 'endUserURL', sortable: true, fixedWidth: 250, type: 'url',
        typeAttributes: {label: { fieldName: 'customerName' }, target: '_self'}
    },
    { label: 'Sales Rep', fieldName: 'salesRep', fixedWidth: 180},
    { label: 'Finance Type', fieldName: 'financeType', sortable: true, fixedWidth: 100},
    { label: 'Term', fieldName: 'term', sortable: true, fixedWidth: 100},
    { label: 'Payments Remaining', fieldName: 'remainPay', sortable: true, fixedWidth: 100 },
    { label: 'Health', fieldName: 'health', sortable: true, fixedWidth: 100 },
    { label: 'Status', fieldName: 'status', sortable: true,fixedWidth: 100  }
    
];

//const columns2 = [
    //{ label: 'Contract', fieldName: 'contractNumber', wrapText:false, /*initialWidth: 200,*/ sortable: true},
    //{ label: 'Customer Name', fieldName: 'customerName', /*initialWidth: 200,*/ sortable: true },
    //{ label: 'Sales Rep', fieldName: 'salesRep', /*initialWidth: 200,*/ sortable: true },
    //{ label: 'Finance Type', fieldName: 'financeType',  /*initialWidth: 110,*/ sortable: true},
    //    { label: 'Serial(s)', fieldName: 'serials', /*initialWidth: 150,*/ sortable: true},
    // { label: 'Make(s)', fieldName: 'makes',  /*initialWidth: 150,*/ sortable: true  },
    // { label: 'Term', fieldName: 'term', /*initialWidth: 100,*/ sortable: true},
    //{ label: 'Payments Remaining', fieldName: 'remainPay', /*initialWidth: 100,*/ sortable: true  },
    //{ label: 'Health', fieldName: 'health', /*initialWidth: 100,*/ sortable: true },
    //{ label: 'Status', fieldName: 'status', /*initialWidth: 120,*/ sortable: true }
//];


export default class PortfolioView extends NavigationMixin(LightningElement) {

    refreshExecute = true;
    portfoliolist = [];
    error; 
    columns=columns;
    maxRows=100;
    totalRecords=null;
    offSet=0;
    loadMoreStatus;
    targetDataTable;
    searchDate=0;
    isLoading=true;
    filter;
    savelist;
    totalRecords=0;
    itemCount;
    orderByField;
    orderByDirection;
    downloaddata =[];    
    @track salesRepFilter = '';
    @track allValues = [];
    @track status='';
      
    datelist = [
        {value: '0', label: 'All Time'},
        {value: 'LAST_N_DAYS:30', label: 'Last 30 Days'},
        {value: 'LAST_N_DAYS:60', label: 'Last 60 Days'},
        {value: 'LAST_N_DAYS:90', label: 'Last 90 Days'},
        {value: 'LAST_N_MONTHS:12', label: 'Last 12 Months'},
        {value: '2021', label: '2021'},
        {value: '2020', label: '2020'},
        {value: '2019', label: '2019'}
    
    ];

    statuslist = [
        {value: '', label: 'ALL'},
        {value: 'BOOKED', label: 'BOOKED'},
        {value: 'EVERGREEN', label: 'EVERGREEN'},
        {value: 'TERMINATED', label: 'TERMINATED'}
    ];

    connectedCallback() {
        //Get initial chunk of data with offset set at 0
        this.getRecords();
        //Commenting the below callback method - this will improve the performance      
        
    }
     
    getRecords() { 
        if (this.offSet == 0){

            getTotalRecords()
                .then(result => {
                     
                    result = JSON.stringify(result);
                    if(result){ 
                         
                        this.totalRecords=result;
                        if (this.totalRecords > 20)
                            this.itemCount = 20 + '+';
                        else   
                            this.itemCount = result;
                        if (this.filter != null){
                            this.itemCount = this.portfoliolist.length;
                           
                        }
                    }
                }) 
                .catch(error => {
                    this.error = error;
                    this.data = undefined;
                    console.log('error : ' + JSON.stringify(this.error));
                    this.showToast('Something went wrong', JSON.stringify(this.error), 'error');
                    return;
                });
        }

        getRecords({
            offSetCount : this.offSet,
            months: this.searchDate,
            status: this.allValues,
            orderByField: this.orderByField,
            orderByDirection : this.orderByDirection,
            filter :this.filter,
            isDownload : false,
            salesRepFilter: this.salesRepFilter }) 
            .then(result => {
                let preparedLeases = [];
                
                result = JSON.parse(result);
                if (result) {
                    result.forEach(contract => {     
                       
                        let preparedLease = {}; 
                        preparedLease.Id = contract.contract.Id;
                        preparedLease.contractNumber = contract.contract.Name;
                        if (contract.contract.End_User__r != undefined) {
                            if (contract.contract.End_User__r.Name != undefined) {
                                preparedLease.customerName = contract.contract.End_User__r.Name;
                                preparedLease.endUserURL = window.location.origin + '/dllondemand/s/account/' + contract.contract.End_User__c;
                            }
                        } else if (contract.contract.Opportunity__r == undefined) {
                            preparedLease.customerName = '';
                            preparedLease.endUserURL = '';     
                        } else if (contract.contract.Opportunity__r.End_User__r != undefined) {
                            preparedLease.customerName = contract.contract.Opportunity__r.End_User__r.Name;                                
                            preparedLease.endUserURL = window.location.origin + '/dllondemand/s/account/' + contract.contract.Opportunity__r.End_User__r.Id;
                        } else {
                            preparedLease.customerName = '';
                            preparedLease.endUserURL = '';
                        } 

                        if(contract.contract.Opportunity__r) {
                            console.log('have Opp');
                            if(contract.contract.Opportunity__r.Partner_Sales_Rep__r) {
                                console.log('have partner Sales Rep');
                                preparedLease.salesRep =  contract.contract.Opportunity__r.Partner_Sales_Rep__r.Name;
                            } else {
                                preparedLease.salesRep = '';
                            }
                        }else{
                            console.log('no have Opp');
                            preparedLease.salesRep = '';
                        }

                        
                        //preparedLease.salesRep = contract.contract.Sales_Rep_Name__c;
                        preparedLease.financeType = contract.contract.Purchase_Option__c;   
                        preparedLease.term = contract.contract.Contract_Term_months__c;
                        preparedLease.remainPay = contract.contract.Payments_Remaining__c;
                        preparedLease.serials = contract.serial;
                        preparedLease.makes = contract.make;
                        preparedLease.health = contract.contract.Delinquency_Status__c;
                        preparedLease.status = contract.contract.Status_Text__c;
                        preparedLease.contractUrl = window.location.origin + '/dllondemand/s/contract/' +  contract.contract.Id;

                        preparedLeases.push(preparedLease);
                    });
                    this.portfoliolist = [...this.portfoliolist, ...preparedLeases];
										this.savelist = this.portfoliolist;
                     
                    console.log('size of list' + this.portfoliolist.length);
                    this.itemCount = this.portfoliolist.length;
                    this.error = undefined;
                    this.loadMoreStatus = '';
                     
                    if (this.portfoliolist.length < 20){
                        this.isLoading = false;
                        this.loadMoreStatus = 'No more data to load';
                    }
                     
                    if (this.targetDataTable && this.targetDataTable.length >= this.maxRows) {
                        //stop Infinite Loading when threshold is reached
                        this.targetDataTable.enableInfiniteLoading = false;
                        //Display "No more data to load" when threshold is reached
                        this.loadMoreStatus = 'No more data to load';
                    }
                     
                    //Disable a spinner to signal that data has been loaded
                    if (this.targetDataTable){
                        this.targetDataTable.isLoading = false;
                    }
                     
                }
                else{
                    this.loadMoreStatus = 'No more data to load';
                    this.targetDataTable.isLoading = false;
                    return;
                }
            }) 
            .catch(error => {
                this.error = error;
                this.data = undefined;
                console.log('error : ' + JSON.stringify(this.error));
                this.showToast('Something went wrong', JSON.stringify(this.error), 'error');
                return;
            });
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant,
            mode: 'sticky'
        });
        this.dispatchEvent(event);
    }

        
    //Start PBI 943211 - Vinicio Ramos Silva - Application Listview Download functionality for Quote & Portfolio
    handleDownload(event) {
       
        let date = new Date()
        let day = date.getDate();
        let month = date.getMonth()+1;
        let year = date.getFullYear();
        let fullDate = month + "-" + day + "-" + year;

        if (this.offSet == 0){
            getTotalRecords()
                .then(result => {                     
                    result = JSON.stringify(result);
                    if(result){                          
                        this.totalRecords=result;
                        if (this.totalRecords > 20)
                            this.itemCount = 20 + '+';
                        else   
                            this.itemCount = result;
                        if (this.filter != null){
                            this.itemCount = this.portfoliolist.length;                           
                        }
                    }
                }) 
                .catch(error => {
                    this.error = error;
                    this.data = undefined;
                    console.log('error : ' + JSON.stringify(this.error));
                    this.showToast('Something went wrong', JSON.stringify(this.error), 'error');
                    return;
                });
        }

        getRecords({
            offSetCount : this.offSet,
            months: this.searchDate,
            status: this.allValues,
            orderByField: this.orderByField,
            orderByDirection : this.orderByDirection,
            filter : this.filter,
            isDownload : true })
            .then(res => {
                const evt = new ShowToastEvent({
                    // title: 'Download Portfolio',
                     message: 'Downloading....',
                     variant: 'success',
                     duration:10000,
                 });
                 this.dispatchEvent(evt);
                 
                let downloaddata = [];
                res = JSON.parse(res);                
                if (res) {                    
                    res.forEach(contract => { 
                        let preparedLease = {}; 
                        preparedLease.contractNumber = contract.contract.Name;
                        if (contract.contract.End_User__r != undefined) {
                            if (contract.contract.End_User__r.Name != undefined) {
                                preparedLease.customerName = contract.contract.End_User__r.Name;
                            }
                        } else if (contract.contract.Opportunity__r == undefined) {
                            preparedLease.customerName = '';
                        } else if (contract.contract.Opportunity__r.End_User__r != undefined) {
                            preparedLease.customerName = contract.contract.Opportunity__r.End_User__r.Name;                                
                        } else {
                            preparedLease.customerName = '';
                        } 
                        preparedLease.salesRep = contract.contract.Sales_Rep_Name__c;
                        preparedLease.financeType = contract.contract.Purchase_Option__c;   
                        preparedLease.term = contract.contract.Contract_Term_months__c;
                        preparedLease.remainPay = contract.contract.Payments_Remaining__c;
                        preparedLease.health = contract.contract.Delinquency_Status__c;
                        preparedLease.status = contract.contract.Status_Text__c;

                        downloaddata.push(preparedLease);
                    })
                }          
      
        if(!downloaddata.length){
            return null
        }
        
        const jsonObject = JSON.stringify(downloaddata);        
        const result = this.convertToXLS(downloaddata, this.headers);
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
            'Contract',
            'Customer Name',
            'Sales Rep',
            'Finance Type',
            'Term',
            'Payments Remaining', 
            'Health',            
            'Status'
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
            doc += '<th>'+record.contractNumber+'</th>';
            doc += '<th>'+record.customerName+'</th>';
            doc += '<th>'+record.salesRep+'</th>';
            doc += '<th>'+record.financeType+'</th>'; 
            doc += '<th>'+record.term+'</th>'; 
            doc += '<th>'+record.remainPay+'</th>'; 
            doc += '<th>'+record.health+'</th>'; 
            doc += '<th>'+record.status+'</th>';
            doc += '</tr>';

        });
        doc += '</table>';
        var element = 'data:application/vnd.ms-excel,' + encodeURIComponent(doc);
        let downloadElement = document.createElement('a');
        downloadElement.href = element;
        downloadElement.target = '_self';
        // use .csv as extension on below line if you want to export data as csv
        downloadElement.download = 'Portfolios ' + fullDate +'.xls';
        document.body.appendChild(downloadElement);
        downloadElement.click();

    } 
    //End PBI 943211 - Vinicio Ramos Silva - Application Listview Download functionality for Quote & Portfolio

    loadMoreData(event) {
         
        event.preventDefault();
        // increase the offset count by 20 on every loadmore event
        this.offSet = this.offSet + 20;

        if (this.offSet > 20)
            this.itemCount = this.offSet + '+';

        //Display a spinner to signal that data is being loaded
        this.isLoading = true;
        event.target.isLoading = true;
        //Set the onloadmore event taraget to make it visible to imperative call response to apex.
        this.targetDataTable = event.target;
        //Display "Loading" when more data is being loaded
        this.loadMoreStatus = 'Loading';
        // Get new set of records and append to this.data
        this.getRecords();
         
    }

    //Geetha added to handle logic for select date filter
    handleChangeDate(event) {
        this.searchDate = event.target.value;
        console.log('this.searchDate ' +this.searchDate);
        this.enableInfiniteLoading = true;
        this.isLoading =true;
        this.portfoliolist = [];
        this.rowOffset = 0;
        this.getRecords();
    }

    handleChange(event) {

        this.isLoading=true;
        this.searchDate = event.detail.value;
        this.portfoliolist = [];
        this.offSet = 0;
        this.allValues = '';
        this.getRecords();
        
    }

    handleChangeStatus(event) {
        console.log('entrou status');
        console.log('entrou event.target.value   '+ event.target.value);
        if(event.target.value == ''){
            this.allValues = [];
            this.status=''; 
        }
        else{
            if(!this.allValues.includes(event.target.value)){           
                this.allValues.push(event.target.value); 
            }                
        }
        
        this.isLoading=true;        
        this.portfoliolist = [];
        this.offSet = 0;
        this.getRecords();        
    }
    //Start PBI 943211 - Vinicio Ramos Silva - Application Listview Download functionality for Quote & Portfolio
    handleChangeSalesRep(event) {
        this.salesRepFilter = event.target.value;
        clearTimeout(this.debounceTimeout);
        this.debounceTimeout = setTimeout(() => {
            this.enableInfiniteLoading = true;
            this.isLoading =true;
            this.portfoliolist = [];
            this.offSet = 0;
            this.getRecords();
         }, 2000);
        
    }

    handleRemove(event){
        
        const valueRemoved = event.target.name;
        this.allValues.splice(this.allValues.indexOf(valueRemoved),1);
        this.isLoading=true;        
        this.portfoliolist = [];
        this.offSet = 0;
        this.getRecords();        
    }

    handleClearFilters(event){
 
        this.allValues = [];
        this.searchDate = '0';        
        this.status='ALL';
        this.salesRepFilter='';        
        this.offSet = '0';        
        this.sortDirection='desc';
        this.loadMoreStatus = '';
        this.initialDataLoaded = false;        
        this.enableInfiniteLoading = true;
        this.isLoading =true;
        this.portfoliolist = [];
               
        this.getRecords();
    }
    //End PBI 943211 - Vinicio Ramos Silva - Application Listview Download functionality for Quote & Portfolio

    /*Commenting this method as its a duplicate*/
    /*handleChange(event) {
        console.log('filter is' + event.detail.value);

        this.isLoading=true;
        this.filter = event.detail.value;
        
    }*/

    resetList(event) {       

        if(event.detail.value){ 
            return;
        }
        else{
           
            this.filter = '';
            this.portfoliolist = [];
            this.portfoliolist = this.savelist;
            this.isLoading=true;
            this.getRecords();
        }
    }
    
    handleFilter(event){
     
        if (event.keyCode == 13){
            this.filter = event.target.value;
            this.portfoliolist = [];
            this.isLoading=true;
            this.offSet = 0;
            this.getRecords();
        }
    }

    updateColumnSorting(event) {
        //new code Geetha - to fix the column sorting issue 
        this.orderByField = event.detail.fieldName;
        this.orderByDirection = event.detail.sortDirection;
        this.enableInfiniteLoading = true;
        this.isLoading =true;
        this.portfoliolist = [];
        this.rowOffset = 0;
        this.getRecords();
    }
}