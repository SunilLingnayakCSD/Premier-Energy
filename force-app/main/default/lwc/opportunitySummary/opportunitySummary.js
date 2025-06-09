import { LightningElement } from 'lwc';
import salesRepIcon from '@salesforce/resourceUrl/wp';
import contactIcon from '@salesforce/resourceUrl/ebidta';
import csatIcon from '@salesforce/resourceUrl/grossmargin';
import revenueIcon from '@salesforce/resourceUrl/negotiation';

export default class OpportunitySummary extends LightningElement {
  salesRepIcon = salesRepIcon;
    contactIcon = contactIcon;
    csatIcon = csatIcon;
    revenueIcon = revenueIcon;
    // growthIcon = growthIcon;
    // last12Icon = last12Icon;
}