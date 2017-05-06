/*******************************************************************************
 * Copyright (c) 2017 itemis AG (http://www.itemis.eu) and others.
 * All rights reserved. This program and the accompanying materials
 * are made available under the terms of the Eclipse Public License v1.0
 * which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *******************************************************************************/
package org.eclipse.xtext.example.domainmodel.ui.contentassist

import com.google.common.base.Predicate
import com.google.inject.Inject
import org.eclipse.emf.ecore.EReference
import org.eclipse.jface.text.contentassist.ICompletionProposal
import org.eclipse.xtext.CrossReference
import org.eclipse.xtext.EcoreUtil2
import org.eclipse.xtext.conversion.IValueConverter
import org.eclipse.xtext.naming.IQualifiedNameConverter
import org.eclipse.xtext.resource.IEObjectDescription
import org.eclipse.xtext.scoping.IScope
import org.eclipse.xtext.scoping.IScopeProvider
import org.eclipse.xtext.ui.editor.contentassist.ConfigurableCompletionProposal
import org.eclipse.xtext.ui.editor.contentassist.ConfigurableCompletionProposal.IReplacementTextApplier
import org.eclipse.xtext.ui.editor.contentassist.ContentAssistContext
import org.eclipse.xtext.ui.editor.contentassist.ICompletionProposalAcceptor
import org.eclipse.xtext.xbase.imports.RewritableImportSection
import org.eclipse.xtext.xbase.ui.imports.ReplaceConverter
import org.eclipse.xtext.xtype.XImportSection
import org.eclipse.emf.ecore.EObject
import org.eclipse.xtext.Assignment
import org.eclipse.emf.ecore.EcoreFactory

import com.google.common.base.Predicates
import org.eclipse.xtext.example.domainmodel.domainmodel.DomainmodelPackage
import org.eclipse.xtext.example.domainmodel.ui.contentassist.DomainmodelImportingTypesProposalProvider.FQNImporter
import org.eclipse.xtext.example.domainmodel.ui.contentassist.DomainmodelImportingTypesProposalProvider.FQNImporter

/**
 * @author atanaka - Initial contribution and API
 */
class DomainmodelProposalProvider extends AbstractDomainmodelProposalProvider {
	@Inject
	private RewritableImportSection.Factory importSectionFactory;
	@Inject
	private ReplaceConverter replaceConverter;
	@Inject
	private IScopeProvider scopeProvider;

	override completeProperty_Type(EObject model, Assignment assignment, ContentAssistContext context,
		ICompletionProposalAcceptor acceptor) {
		val crossRef = assignment.getTerminal() as CrossReference
		val EReference eref = EcoreFactory.eINSTANCE.createEReference()
		eref.setEType(DomainmodelPackage.Literals.ENTITY)
		lookupCrossReference(crossRef, eref, context, acceptor, Predicates.<IEObjectDescription>alwaysTrue())
	}

	override protected lookupCrossReference(CrossReference crossReference, EReference reference,
		ContentAssistContext contentAssistContext, ICompletionProposalAcceptor acceptor,
		Predicate<IEObjectDescription> filter) {
			super.lookupCrossReference(crossReference, reference, contentAssistContext,
				new ICompletionProposalAcceptor() {

					override accept(ICompletionProposal proposal) {
						if (proposal instanceof ConfigurableCompletionProposal) {
							proposal.textApplier = createTextApplier(
								contentAssistContext,
								scopeProvider.getScope(contentAssistContext.currentModel, reference),
								qualifiedNameConverter,
								qualifiedNameValueConverter
							)
						}
						acceptor.accept(proposal)
					}

					override canAcceptMoreProposals() {
						acceptor.canAcceptMoreProposals()
					}

				}, filter)
		}

		def IReplacementTextApplier createTextApplier(ContentAssistContext context, IScope typeScope,
			IQualifiedNameConverter qualifiedNameConverter, IValueConverter<String> valueConverter) {
			if (EcoreUtil2.getContainerOfType(context.getCurrentModel(), XImportSection) !== null)
				return null;
			return new FQNImporter(context.getResource(), context.getViewer(), typeScope, qualifiedNameConverter,
				valueConverter, importSectionFactory, replaceConverter);
		}

	}
	