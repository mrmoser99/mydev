import { LightningElement, api, track } from 'lwc';
import getChildContacts from '@salesforce/apex/GetChildHierarchyRecursive.getChildContacts';
import createPartnerUser from '@salesforce/apex/GetChildHierarchyRecursive.createPartnerUser';
import { NavigationMixin } from 'lightning/navigation';

const columns = [
    { label: 'FirstName', fieldName: 'FirstName', type:'text'},
    { label: 'LastName', fieldName: 'LastName',type:'text' },
    { label: 'Email', fieldName: 'Email',type:'text' },
    { label: 'Location', fieldName: 'Location',type:'text' },
    { label: 'Role', fieldName: 'Role',type:'text' }
    
];


export default class DodChildAccountHierarchy extends NavigationMixin(LightningElement) {
    @api account = [];

    @track data=[];
    @track columns = columns;
    @track selectedRows = [];

    tableElement;
    maxRowCount;
    dataAll = [];
    recordCount =20;
    loadMoreStatus;
    showfirstTable = true;
    srcString = '';
    rawData = [];

    connectedCallback(){
        this.showfirstTable = true;
        console.log('thisacc' +this.account);
       
        getChildContacts({accountId:this.account})
        .then(result=>{
            /*console.log('dodresult' +JSON.stringify(result));
            this.data = [...result];
            this.maxRowCount = this.data.length;
            this.data.map(dt=>{
             dt.Location = dt.Account.Name;
             dt.Role = dt.Role__c;
            })
            //this.data = con;
            this.dataAll = this.data;
            this.data = this.dataAll.slice(0,this.recordCount);
            console.log('dataAll = ' +JSON.stringify(this.dataAll));
            console.log('data= ' +JSON.stringify(this.data));*/
            this.rawData = result;
            this.prepareData(this.rawData);
        })
       

    }

    //To do pagination
    prepareData(allData){
        console.log('allData in preparedata' +JSON.stringify(allData));
        this.data = [...allData];
        this.maxRowCount = this.data.length;
        this.data.map(dt=>{
         dt.Location = dt.Account.Name;
         dt.Role = dt.Role__c;
        })
        //this.data = con;
        this.dataAll = this.data;
        this.data = this.dataAll.slice(0,this.recordCount);
        console.log('dataAll = ' +JSON.stringify(this.dataAll));
        console.log('data= ' +JSON.stringify(this.data));
    }
      
    
    //loadMoreData
    loadMoreData(event){

        if(this.nameSearchStr || this.roleSearchStr || this.locSearchStr){
            return;
        }

        console.log('load more data');
        if(event.target){
            event.target.isLoading = true;
        }
        this.tableElement = event.target;
        this.loadMoreStatus = 'Loading';
        this.recordCount = this.recordCount + 20;
        this.recordCount = (this.recordCount > this.maxRowCount) ? this.maxRowCount : this.recordCount;
        this.data = this.dataAll.slice(0,this.recordCount);
        this.loadMoreStatus = '';
        if(this.tableElement){
            this.tableElement.isLoading = false;
        }
    }

    //getSelectedRows

    getSelectedRows(event){
        this.selectedRows = event.detail.selectedRows;
    }

    //handleContinue button
    handleContinue(event){
        console.log('inside continue');
       this.showfirstTable = false;
    }

    handleBack(event){
        this.showfirstTable = true;
    }

    //Search by Name
handleAllSearch(event) {
    this.tempdata = [...this.dataAll];
    console.log('event name = ' + event.target.name);
    if (event.target.name == 'name') {
        this.nameSearchStr = event.target.value;
    }
    if (event.target.name == 'role') {
        this.roleSearchStr = event.target.value;
    }
    if (event.target.name == 'loc') {
       
        this.locSearchStr = event.target.value;
        console.log('loc value ' +this.locSearchStr);
    }

    if ((typeof (this.nameSearchStr) == 'undefined' || this.nameSearchStr == '') &&

        (typeof (this.roleSearchStr) == 'undefined' || this.roleSearchStr == '') &&
        
        (typeof (this.locSearchStr) == 'undefined' || this.locSearchStr == '')) {

        this.data = this.dataAll
        return;

    }
    console.log('scr string = ' + JSON.stringify(event.target.value));

    console.log('inside if first if handlenamesearch');
   
    console.log('inside if handlenamesearch');
    if(this.nameSearchStr){
     this.tempdata = this.tempdata.filter(dt => {

        let nameSearchData = '';
       
            if (dt.FirstName) {
                nameSearchData = dt.FirstName;
            }
            if (dt.LastName) {
                console.log('inside ln');
                nameSearchData = nameSearchData + dt.LastName;
                console.log('nameSearchData in ln ' + nameSearchData);
            }
            if (dt.Email) {
                console.log('inside email');
                nameSearchData = nameSearchData + dt.Email;
                console.log('nameSearchData in email ' + nameSearchData);
            }
            console.log('nameSearchData = ' + nameSearchData);
            if (nameSearchData.toUpperCase().includes(this.nameSearchStr.toUpperCase())) {
                console.log('dt3 ' + JSON.stringify(dt));
                return dt;
            }
   
    });
}
        //Role search
        if ( this.roleSearchStr) {
            console.log('inside rolesearch');
            this.tempdata =   this.tempdata.filter(dt => {
                let roleSearchData = '';
                roleSearchData =  dt.Role;
                if(roleSearchData){

                if (roleSearchData.toUpperCase().includes(this.roleSearchStr.toUpperCase())) {
                    console.log('dt2 ' + JSON.stringify(dt));
                    return dt;
                }
            }
            });
        }


        //Location search
        if ( this.locSearchStr) {
            console.log('inside locsearch');
            this.tempdata =   this.tempdata.filter(dt => {
                let locSearchData = '';
                locSearchData =  dt.Location;
                if(locSearchData){

                if (locSearchData.toUpperCase().includes(this.locSearchStr.toUpperCase())) {
                    console.log('dt2 ' + JSON.stringify(dt));
                    return dt;
                }
            }
            });
        }

        this.data=this.tempdata;
        console.log('this.data in 173' +JSON.stringify(this.data));
        console.log('this.roleSearchStr = ' + this.roleSearchStr);
        console.log('this.namesearchStr = ' + this.nameSearchStr);
}

//method to create User - by calling apex method
handleCreateUser(){
    console.log('inside handlec cre');
    let profileName = this.template.querySelector('c-partner-o-b-create-user').getProfileName();
    console.log('profileName = ' +profileName);
    console.log('contact ids ' +JSON.stringify(this.selectedRows ));
    console.log('contact ids ' +JSON.stringify(this.selectedRows ));
    let ids = [];
    
    this.selectedRows.map(con=>{
        ids.push(con.Id);
      
      })
      
      createPartnerUser({
              profileName: profileName,
              contactIds: ids
          }).then(result => {
      
              this.showToast('Partner User created Successfully', result, 'success');
      
          }).catch(error => {
              console.log('error' + JSON.stringify(error));
              this.loader = false;
          })
   
   /* createPartnerUser({
        profileName:
    }).then(result => {


        this.showToast('Partner User created Successfully', result, 'success');

    }).catch(error => {
        console.log('error' + JSON.stringify(error));
        this.loader = false;
    })*/

}
}