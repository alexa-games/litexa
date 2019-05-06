/*
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 * Copyright 2019 Amazon.com (http://amazon.com/), Inc. or its affiliates. All Rights Reserved. 
 * These materials are licensed as "Restricted Program Materials" under the Program Materials 
 * License Agreement (the "Agreement") in connection with the Amazon Alexa voice service. 
 * The Agreement is available at https://developer.amazon.com/public/support/pml.html. 
 * See the Agreement for the specific terms and conditions of the Agreement. Capitalized 
 * terms not defined in this file have the meanings given to them in the Agreement. 
 * ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 */

import {expect} from 'chai';
import {addNumbers, todayName} from './utils';

describe('utils', () => {
    describe('#todayName', () => {
        it('returns the days of the week correctly', () => {
            expect(todayName(new Date(Date.parse('Jan 6 2019')))).to.equal('Sunday');
            expect(todayName(new Date(Date.parse('Jan 7 2019')))).to.equal('Monday');
            expect(todayName(new Date(Date.parse('Jan 8 2019')))).to.equal('Tuesday');
            expect(todayName(new Date(Date.parse('Jan 9 2019')))).to.equal('Wednesday');
            expect(todayName(new Date(Date.parse('Jan 10 2019')))).to.equal('Thursday');
            expect(todayName(new Date(Date.parse('Jan 11 2019')))).to.equal('Friday');
            expect(todayName(new Date(Date.parse('Jan 12 2019')))).to.equal('Saturday');
        });
    });
    describe('#addNumbers', () => {
        it('defaults to 0', () => {
            expect(addNumbers()).to.equal(0);
        });
        it('sums correctly', () => {
            expect(addNumbers(1,2,3)).to.equal(6);
        });
    });
});
