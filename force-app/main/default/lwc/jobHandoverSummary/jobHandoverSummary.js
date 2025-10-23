import { LightningElement, api } from 'lwc';

export default class VisualforceEmbedder extends LightningElement {
    @api recordId; // Current Opportunity ID
    
    // Computed property for Visualforce URL
  connectedCallback() {
    console.log('LWC loaded. Record ID: ', this.recordId);

       
    }
  get vfPageUrl() {
        return `/apex/JobHandoverSummary?recordId=${this.recordId}`;
    }
    handleIframeLoad() {
        // Optional: Handle when the iframe finishes loading
        console.log('Visualforce page loaded');
    }
}