// import { LightningElement, wire, track } from 'lwc';
// import getImageUrls from '@salesforce/apex/PromoContentController.getImageUrls';

// export default class PromoCarousel extends LightningElement {
//     @track imageUrls = [];

//     @wire(getImageUrls)
//     wiredImageUrls({ error, data }) {
//         if (data) {
//             this.imageUrls = data;
//         } else if (error) {
//             console.error('Error fetching image URLs:', error);
//             this.imageUrls = [];
//         }
//     }
// }



// import { LightningElement, wire, track } from 'lwc';
// import getImageUrls from '@salesforce/apex/PromoContentController.getImageUrls';

// export default class PromoCarousel extends LightningElement {
//     @track imageUrls = [];

//     @wire(getImageUrls)
//     wiredImageUrls({ error, data }) {
//         if (data) {
//             this.imageUrls = data;
//         } else if (error) {
//             console.error('Error fetching image URLs:', error);
//             this.imageUrls = [];
//         }
//     }
// }


// import { LightningElement, wire } from 'lwc';
// import getImageUrls from '@salesforce/apex/PromoContentController.getImageUrls';

// export default class PromoCarousel extends LightningElement {
//     imageUrls = [];
//     scrollInterval;
//     currentIndex = 0;

//     @wire(getImageUrls)
//     wiredImageUrls({ error, data }) {
//         if (data) {
//             this.imageUrls = data;
//             this.startAutoScroll();
//         } else if (error) {
//             console.error('Error fetching image URLs:', error);
//         }
//     }

//     startAutoScroll() {
//         this.scrollInterval = setInterval(() => {
//             const carousel = this.template.querySelector('lightning-carousel');
//             if (carousel) {
//                 this.currentIndex = (this.currentIndex + 1) % this.imageUrls.length;
//                 carousel.scrollTo(this.currentIndex);
//             }
//         }, 3000); 
//     }

//     disconnectedCallback() {
//         clearInterval(this.scrollInterval);
//     }
// }

// import { LightningElement, wire, track } from 'lwc';
// import getImageUrls from '@salesforce/apex/PromoContentController.getImageUrls';

// export default class PromoCarousel extends LightningElement {
//     @track imageUrls = [];
//     currentIndex = 0;
//     trackStyle = "transform: translateX(0);";

//     @wire(getImageUrls)
//     wiredImageUrls({ error, data }) {
//         if (data) {
//             this.imageUrls = [...data, ...data]; 
//             this.startAutoScroll();
//         } else if (error) {
//             console.error('Error fetching image URLs:', error);
//         }
//     }

//     startAutoScroll() {
//         let scrollAmount = 0;
//         const step = 1;
//         setInterval(() => {
//             scrollAmount -= step;
//             if (scrollAmount <= -100 * (this.imageUrls.length / 2)) {
//                 scrollAmount = 0;
//             }
//             this.trackStyle = `transform: translateX(${scrollAmount}%);`;
//         }, 120); 
//     }
// }



// import { LightningElement, wire, track } from 'lwc';
// import getImageUrls from '@salesforce/apex/PromoContentController.getImageUrls';

// export default class PromoCarousel extends LightningElement {
//     @track imageUrls = [];
//     currentIndex = 0;
//     trackStyle = "transform: translateX(0);";
//     autoScrollInterval;

//     get visibleImageUrls() {
//         return this.imageUrls.slice(0, this.imageUrls.length / 2);
//     }

//     get dotStyles() {
//         return this.visibleImageUrls.map((_, index) => ({
//             style: index === this.currentIndex ? 'background-color: black;' : 'background-color: gray;',
//             index: `dot-${index}`
//         }));
//     }

//     @wire(getImageUrls)
//     wiredImageUrls({ error, data }) {
//         if (data) {
//             this.imageUrls = [...data, ...data];
//             this.startAutoScroll();
//         } else if (error) {
//             console.error('Error fetching image URLs:', error);
//         }
//     }

//     startAutoScroll() {
//         this.autoScrollInterval = setInterval(() => {
//             this.currentIndex = (this.currentIndex + 1) % this.visibleImageUrls.length;
//             this.updateTrackStyle();
//         }, 3000);
//     }

//     updateTrackStyle() {
//         this.trackStyle = `transform: translateX(-${this.currentIndex * 100}%);`;
//     }

//     handleDotClick(event) {
//         clearInterval(this.autoScrollInterval); 
//         this.currentIndex = parseInt(event.target.dataset.index.replace('dot-', ''), 10);
//         this.updateTrackStyle();
//         this.startAutoScroll();
//     }
// }






import { LightningElement, wire, track } from 'lwc';
import getImageBase64 from '@salesforce/apex/PromoContentController.getImageBase64';

export default class PromoCarousel extends LightningElement {
    @track imageUrls = [];
    trackStyle = "transform: translateX(0%);";
    scrollPosition = 0;

    @wire(getImageBase64)
    wiredImageUrls({ error, data }) {
        if (data) {
            let uniqueImages = [...new Set(data)]; 
            this.imageUrls = [...uniqueImages, ...uniqueImages]; 
            this.startAutoScroll();
        } else if (error) {
            console.error('Error fetching images:', error);
        }
    }

    startAutoScroll() {
        const step = 0.3; 
        setInterval(() => {
            this.scrollPosition -= step;
            if (this.scrollPosition <= -100 * (this.imageUrls.length / 2)) {
                this.scrollPosition = 0;
            }
            this.trackStyle = `transform: translateX(${this.scrollPosition}%);`;
        }, 10);
    }
}




// import { LightningElement, wire, api, track } from 'lwc';
// import getImageUrls from '@salesforce/apex/PromoContentController.getImageUrls';
// import { ShowToastEvent } from 'lightning/platformShowToastEvent';

// export default class PromoCarousel extends LightningElement {
//     @track imageUrls = [];
//     @api recordId; 
//     flowInputVariables = [];

//     originalCount = 0;
//     trackStyle = "transform: translateX(0%)";
//     scrollPosition = 0;

//     connectedCallback() {
//         if (this.recordId) {
//             this.flowInputVariables = [
//                 {
//                     name: "recordId",
//                     type: "String",
//                     value: this.recordId
//                 }
//             ];
//         }
//     }

//     @wire(getImageUrls)
//     wiredImageUrls({ error, data }) {
//         if (data) {
//             const unique = [...new Set(data)];
//             this.imageUrls = [...unique, ...unique];
//             this.originalCount = unique.length;
//             this.startAutoScroll();
//         } else if (error) {
//             console.error('Error fetching images:', error);
//         }
//     }

//     startAutoScroll() {
//         const step = 0.3;
//         setInterval(() => {
//             this.scrollPosition -= step;
//             if (this.scrollPosition <= -100 * (this.imageUrls.length / 2)) {
//                 this.scrollPosition = 0;
//             }
//             this.trackStyle = `transform: translateX(${this.scrollPosition}%);`;
//         }, 10);
//     }

//     handleFlowFinish(event) {
//         if (event.detail.status === "FINISHED") {
//             getImageUrls().then((data) => {
//                 const unique = [...new Set(data)];
//                 if (unique.length === this.originalCount) {
//                     this.showToast("Upload Blocked", "You can upload only one image per record.", "warning");
//                 } else {
//                     this.imageUrls = [...unique, ...unique];
//                     this.originalCount = unique.length;
//                     this.showToast("Success", "Image uploaded successfully.", "success");
//                 }
//             }).catch(error => {
//                 console.error('Refresh failed:', error);
//                 this.showToast("Error", "Could not refresh image list.", "error");
//             });
//         }
//     }

//     showToast(title, message, variant) {
//         this.dispatchEvent(
//             new ShowToastEvent({
//                 title,
//                 message,
//                 variant
//             })
//         );
//     }
// }