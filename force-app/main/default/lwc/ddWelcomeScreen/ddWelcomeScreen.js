//DLL on Demand - WelcomeScreen Footer used in Welcome Page
//PBI:632924 version1: Geetha Bharadwaj
import { LightningElement, api, track } from 'lwc';
import DLL_LOGO from '@salesforce/resourceUrl/DLL_Logo';
import DLL_DarkBlue_Bg from '@salesforce/resourceUrl/DLL_DarkBlue_Bg';
import DLL_Monitor from '@salesforce/resourceUrl/dd_monitor';
import DLL_Quote from '@salesforce/resourceUrl/dd_quote';
import DLL_phone from '@salesforce/resourceUrl/dd_phone';
import DLL_bar from '@salesforce/resourceUrl/dd_bar';

export default class ddWelcomeScreen extends LightningElement {
   @api dynamicFooter = 'welcomePageFooter';
	@api dynamicDateRange;
   @track dlllogo = DLL_LOGO;
   @track dllDarkBlueBg = DLL_DarkBlue_Bg;
   @track dllDesktop = DLL_Monitor;
   @track dllQuote = DLL_Quote;
   @track dllPhone = DLL_phone;
   @track dllbar = DLL_bar;
		
		get dynamicDateValue() {
				console.log(' this.dynamicDateRange::'+ this.dynamicDateRange);
				return this.dynamicDateRange;
	}
}