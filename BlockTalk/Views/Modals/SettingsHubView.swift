import SwiftUI

struct SettingsHubView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            // Account section
            Section {
                NavigationLink {
                    SettingsProfileView()
                } label: {
                    settingsRow(icon: "person.circle", title: "Profile")
                }

                NavigationLink {
                    SettingsNotificationsView()
                } label: {
                    settingsRow(icon: "bell", title: "Notifications")
                }
            } header: {
                Text("ACCOUNT")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btText3)
            }
            .listRowBackground(Color.btSurface)
            .listRowSeparatorTint(Color.btLine)

            #if DEBUG
            // Testing tools — only visible in debug builds
            Section {
                NavigationLink {
                    SettingsTestingView()
                } label: {
                    settingsRow(icon: "ant", title: "Testing")
                }
            } header: {
                Text("DEVELOPER")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btWarn)
            }
            .listRowBackground(Color.btWarn.opacity(0.08))
            .listRowSeparatorTint(Color.btLine)
            #endif

            // About section
            Section {
                HStack(spacing: BTSpacing.md) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.btText2)
                        .frame(width: 24)
                    Text("Version")
                        .font(BTFont.bodyMedium(size: 15))
                        .foregroundStyle(Color.btText)
                    Spacer()
                    Text(appVersion)
                        .font(BTFont.mono(size: 13))
                        .foregroundStyle(Color.btText3)
                }

                NavigationLink {
                    LegalDocView(title: "Privacy Policy", markdown: LegalDocs.privacy)
                } label: {
                    settingsRow(icon: "hand.raised", title: "Privacy Policy")
                }

                NavigationLink {
                    LegalDocView(title: "Terms of Service", markdown: LegalDocs.terms)
                } label: {
                    settingsRow(icon: "doc.text", title: "Terms of Service")
                }

                NavigationLink {
                    LegalDocView(title: "Community Guidelines", markdown: LegalDocs.guidelines)
                } label: {
                    settingsRow(icon: "checkmark.shield", title: "Community Guidelines")
                }
            } header: {
                Text("ABOUT")
                    .font(BTFont.mono(size: 11))
                    .foregroundStyle(Color.btText3)
            }
            .listRowBackground(Color.btSurface)
            .listRowSeparatorTint(Color.btLine)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(Color.btBg)
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
                    .foregroundStyle(Color.btText2)
            }
        }
    }

    private func settingsRow(icon: String, title: String) -> some View {
        HStack(spacing: BTSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(Color.btText2)
                .frame(width: 24)
            Text(title)
                .font(BTFont.bodyMedium(size: 15))
                .foregroundStyle(Color.btText)
        }
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        return v
    }
}

/// Renders a bundled legal document (no hosting needed). Supports a light subset
/// of Markdown: "## " headings, "- " bullets, "> " quotes, and inline **bold**.
struct LegalDocView: View {
    let title: String
    let markdown: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: BTSpacing.xs) {
                ForEach(Array(markdown.components(separatedBy: "\n").enumerated()), id: \.offset) { _, raw in
                    row(for: raw.trimmingCharacters(in: .whitespaces))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(BTSpacing.xl)
        }
        .background(Color.btBg.ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    @ViewBuilder
    private func row(for line: String) -> some View {
        if line.isEmpty {
            Color.clear.frame(height: BTSpacing.sm)
        } else if line.hasPrefix("## ") {
            Text(String(line.dropFirst(3)))
                .font(BTFont.bodyBold(size: 17))
                .foregroundStyle(Color.btText)
                .padding(.top, BTSpacing.md)
        } else if line.hasPrefix("- ") {
            HStack(alignment: .top, spacing: BTSpacing.sm) {
                Text("•").font(BTFont.body(size: 14)).foregroundStyle(Color.btText3)
                Text(attributed(String(line.dropFirst(2))))
                    .font(BTFont.body(size: 14)).foregroundStyle(Color.btText2).lineSpacing(3)
            }
        } else if line.hasPrefix("> ") {
            Text(attributed(String(line.dropFirst(2))))
                .font(BTFont.body(size: 14)).foregroundStyle(Color.btText2).lineSpacing(3)
                .padding(.leading, BTSpacing.md)
        } else {
            Text(attributed(line))
                .font(BTFont.body(size: 14)).foregroundStyle(Color.btText).lineSpacing(4)
        }
    }

    private func attributed(_ s: String) -> AttributedString {
        (try? AttributedString(markdown: s)) ?? AttributedString(s)
    }
}

/// Identifiable reference so a legal doc can drive an item-based sheet (e.g. the
/// sign-in screen's "terms" / "community rules" links).
struct LegalDocRef: Identifiable {
    let id: String
    let title: String
    let markdown: String

    static let privacy = LegalDocRef(id: "privacy", title: "Privacy Policy", markdown: LegalDocs.privacy)
    static let terms = LegalDocRef(id: "terms", title: "Terms of Service", markdown: LegalDocs.terms)
    static let guidelines = LegalDocRef(id: "guidelines", title: "Community Guidelines", markdown: LegalDocs.guidelines)
}

/// Bundled legal copy. Mirrors /legal/*.md — keep the two in sync when either changes.
enum LegalDocs {
    static let privacy = """
    **Effective & last updated:** August 19, 2026

    ## 1. Who we are
    BlockTalk ("BlockTalk," "we," "us") is an anonymous, hyperlocal social app for New York City neighborhoods. You can read neighborhood conversations from anywhere, but you can only post in the neighborhood you're physically in. Questions: hello@blocktalk.nyc.

    ## 2. The short version
    - You are anonymous to other users — we don't show your real name. You are not anonymous to us or to the law — we hold limited account and technical data and must disclose it when legally compelled.
    - We collect the minimum we need to run the app safely, and we delete on a schedule.
    - We don't sell your personal information to data brokers or share it for third-party advertising.
    - We use a small number of service providers to host the app, keep it safe, and understand product usage.

    ## 3. Information we collect
    **Account & identity.** Your Sign in with Apple identifier (we don't receive your Apple password, and receive your email only if Apple relays it); your chosen username and user number; and your home neighborhood.
    **Content you create.** Posts, replies, votes, reports, and photos you upload. Photos are stored and served to other users as part of your public posts.
    **Location.** To enforce presence-based posting, we check your approximate location to determine which neighborhood you're in, and to attach a neighborhood or corner to street comments.
    **Device & technical.** A push notification token (if enabled), IP address, device and OS type, timestamps, and basic diagnostic and log data.
    **Usage analytics.** Event-level product analytics tied to a pseudonymous identifier, used to improve the product.
    We don't intentionally collect your real name, precise home address, contacts, or sensitive categories of personal data.

    ## 4. How we use your information
    - Operate core features (post, read, reply, vote, notify).
    - Enforce presence-based posting and attach neighborhood context.
    - Keep the community safe: spam prevention, rate limiting, content moderation, and responding to reports.
    - Detect and report illegal content, including our legal obligation to report child sexual abuse material (CSAM) to NCMEC.
    - Send notifications you've opted into, understand usage, improve BlockTalk, and comply with law.

    ## 5. How we share information
    We share personal data only with service providers acting on our behalf — Supabase (hosting, database, authentication, media storage), PostHog (analytics), and Apple (Sign in with Apple; push notifications); for safety and legal reasons — with NCMEC for CSAM, and law enforcement when required by law or to prevent imminent harm; and in a business transfer, subject to this policy.
    We don't sell your personal information to data brokers or share it with third parties for their own advertising. In the future we may show advertising within BlockTalk (for example, from local businesses) and may license aggregated or de-identified information that doesn't identify you — consistent with this policy and applicable law, and we'll update this policy before doing so.

    ## 6. Anonymity — what it means, and what it doesn't
    BlockTalk is anonymous to other users: your posts are not labeled with your real name. But your content is not anonymous to us, and it is not anonymous to a court. Because content is tied to real places and times, we may receive legal requests. We tell you this plainly so you never mistake "anonymous to your neighbors" for "untraceable."

    ## 7. Location
    We use location only to determine your neighborhood for presence-based posting and to place street comments. Where possible we work at the neighborhood level rather than storing a precise, permanent location trail, and any recent-presence data is coarse and expires on a schedule. You can deny location permission — you'll still be able to read and reply, but posting and pinning may be limited.

    ## 8. Photos and user content
    Photos and posts you create are public to other BlockTalk users. Please don't upload anything you wouldn't want shared. All uploaded images are subject to automated and human moderation, including scanning for illegal content.

    ## 9. Analytics
    We use PostHog to collect event-level usage data associated with a pseudonymous identifier, to improve the product. We don't use analytics to identify you to third parties or to sell your data.

    ## 10. Data retention and minimization
    We keep personal data only as long as we need it, then delete or de-identify it on a schedule. Some data is kept longer where required for legal, safety, or security reasons. When you delete your account, we delete or de-identify your account data and content, except records we're legally required to retain.

    ## 11. Security
    We use industry-standard safeguards (encryption in transit, access controls). No system is perfectly secure, but we work to protect your information and to minimize what we hold.

    ## 12. Your choices and rights
    - Account deletion: you can delete your account at any time in Settings, Profile, Delete Account, which removes your posts, replies, and votes. You can also contact hello@blocktalk.nyc.
    - Notifications and location: control in the app or device settings.
    - Region-specific rights: depending on where you live (for example, California), you may have rights to access, delete, correct, or restrict use of your data. We don't sell your personal information to data brokers; if that ever changes, we'll provide a clear opt-out as required by law.

    ## 13. Law enforcement and legal requests
    We may disclose information when we believe in good faith it's required by law, to comply with valid legal process, to enforce our Terms, to address fraud or security, or to prevent imminent harm. We aim to disclose only what we're legally required to disclose. We report CSAM to NCMEC as required by law.

    ## 14. Children
    BlockTalk is intended for users 18 and older. We don't knowingly collect personal data from anyone under 18. If we learn we've collected data from someone under 18, we'll delete it.

    ## 15. Changes to this policy
    We may update this policy as the product and law evolve. If we make material changes, we'll update the date and, where appropriate, notify you in the app.

    ## 16. Contact
    hello@blocktalk.nyc · blocktalk.nyc
    """

    static let terms = """
    **Effective & last updated:** August 19, 2026

    These Terms are a binding agreement between you and BlockTalk governing your use of the app and services (the "Service"). By creating an account or using the Service, you agree to these Terms and to our Privacy Policy and Community Guidelines. If you do not agree, do not use the Service.

    ## 1. Eligibility
    You must be at least 18 years old to use BlockTalk.

    ## 2. The Service
    BlockTalk is an anonymous, hyperlocal social app. You can read from anywhere, but posting and dropping street comments require that you are physically located in the relevant neighborhood ("presence-based posting"). We may change, suspend, or discontinue features at any time.

    ## 3. Your account
    You sign in using Sign in with Apple and choose a username. You are responsible for activity under your account. You are anonymous to other users but not to us.

    ## 4. User conduct and zero tolerance for objectionable content
    You are solely responsible for the content you post. **We have zero tolerance for objectionable content and abusive behavior.** You agree not to post or do any of the following:
    - Hate speech, racism, or content that attacks or demeans people based on protected characteristics.
    - Harassment, bullying, threats, or intimidation; doxxing or identifying and targeting specific private individuals.
    - Content that is illegal, incites violence, or promotes self-harm.
    - Any child sexual abuse material (CSAM) or sexual content involving minors — strictly prohibited and reported to NCMEC and law enforcement.
    - Sexually explicit or pornographic material, or gratuitous violence or gore.
    - Spam, scams, coordinated manipulation, fake engagement, or bots.
    - Impersonation, or posting content that isn't yours or that infringes others' rights.
    - Attempts to circumvent presence-based posting, rate limits, or moderation, or to disrupt or reverse-engineer the Service.
    We may remove content and suspend or terminate accounts that violate these Terms. We provide in-app tools to report content and block users, and we act on reports.

    ## 5. Your content and license to us
    You retain ownership of the content you create. To operate the Service, you grant us a worldwide, non-exclusive, royalty-free license to host, store, display, reproduce, and distribute your content within the Service and its normal operation. This license ends when you delete your account (which removes your posts, replies, and votes), except for copies retained for legal, safety, or backup purposes, or content others have shared.

    ## 6. Content moderation and enforcement
    We use a layered system — automated detection, community reporting, and human review — to enforce our rules. Consequences range from content removal to warnings, temporary suspension, or permanent bans. Where we offer an appeals process, decisions made through it are final.

    ## 7. Platform role (Section 230)
    BlockTalk is a platform that hosts content created by its users. Consistent with Section 230 of the Communications Decency Act, we are not the publisher or speaker of user content, and moderating in good faith does not make us responsible for it. We are not liable for content posted by users. Reports of illegal content: hello@blocktalk.nyc.

    ## 8. Intellectual property and copyright (DMCA)
    The BlockTalk name, logo, and app are our property. If you believe content on BlockTalk infringes your copyright, send a notice to hello@blocktalk.nyc with the required details, and we'll respond to valid notices and may remove infringing content and terminate repeat infringers.

    ## 9. Disclaimers
    The Service is provided "as is" and "as available," without warranties of any kind. We don't warrant that the Service will be uninterrupted, secure, or error-free. You use the Service, and interact with other users and places, at your own risk.

    ## 10. Limitation of liability
    To the maximum extent permitted by law, BlockTalk and its owners, employees, and agents will not be liable for any indirect, incidental, special, consequential, or punitive damages, or any loss of data, goodwill, or profits, arising from your use of the Service. Our total liability for any claim will not exceed the greater of the amount you paid us in the 12 months before the claim, or one hundred dollars ($100).

    ## 11. Indemnification
    You agree to indemnify and hold harmless BlockTalk and its owners, employees, and agents from any claims, damages, or expenses arising from your content, your use of the Service, or your violation of these Terms or any law or third-party right.

    ## 12. Termination
    You may stop using the Service and delete your account at any time. We may suspend or terminate your access at any time for violation of these Terms or to protect the Service or its users.

    ## 13. Governing law and disputes
    These Terms are governed by the laws of the State of New York. Any dispute will be brought exclusively in the state or federal courts located in New York, New York.

    ## 14. Changes to these Terms
    We may update these Terms as the product and law evolve. If we make material changes, we'll update the date and, where appropriate, notify you in the app.

    ## 15. Contact
    hello@blocktalk.nyc · blocktalk.nyc
    """

    static let guidelines = """
    **Effective:** August 19, 2026

    ## The one idea
    Anonymity isn't a hall pass. BlockTalk lets you speak your mind about your block without your name attached — but that freedom only works if it isn't abused. You're anonymous to your neighbors, not to us, and not to the law. Say the real thing. Don't be a menace.

    ## What BlockTalk is for
    Real, local, in-the-moment neighborhood talk — what's happening on your block, the good spots, the honest takes. Post where you actually are. Keep it about the place.

    ## The rules
    - **No hate speech or racism.** No attacks on people based on race, ethnicity, religion, nationality, gender, sexual orientation, disability, or other protected characteristics.
    - **Don't target individuals.** No harassment, bullying, threats, or intimidation. No doxxing — don't post someone's name, address, workplace, or other identifying details to expose or target them.
    - **No threats or violence.** No threats of harm, incitement to violence, or content that promotes self-harm. Threats tied to real places may be reported to law enforcement.
    - **Nothing involving minors, ever.** Zero tolerance for child sexual abuse material (CSAM) or any sexualization of minors. This is illegal, reported to NCMEC and law enforcement, and results in an immediate permanent ban.
    - **Keep it non-explicit.** No pornography, sexually explicit imagery, or gratuitous gore.
    - **No spam or manipulation.** No spam, scams, ads disguised as posts, fake engagement, bots, or coordinated attempts to game the feed or votes.
    - **Be who you are (anonymously).** No impersonating real people or organizations. Don't post content that isn't yours or that infringes someone's rights.
    - **Play it straight.** Don't try to fake your location, dodge rate limits, or work around moderation.
    Everything else is fair game. Strong opinions, neighborhood beef, jokes, criticism of businesses and public figures — that's the point. The line is hate, targeting private people, and illegal content.

    ## How moderation works
    - Report anything that breaks these rules using the in-app report button.
    - Content that gets enough reports is automatically hidden pending review.
    - A real person reviews reports and appeals — moderation isn't purely automated.
    - Photos are scanned automatically for illegal content.

    ## What happens when rules are broken
    Depending on severity, we may remove the content, issue a warning, temporarily suspend the account, or permanently ban. Illegal content — especially anything involving minors — means an immediate permanent ban and a report to the authorities.

    ## Appeals
    If your content was removed or your account was actioned and you think it was a mistake, you can appeal in the app. Appeal decisions are final.

    ## Reporting and contact
    Use the in-app report tools for content. For anything urgent, illegal, or that these tools don't cover, contact hello@blocktalk.nyc. If someone is in immediate danger, contact your local emergency services first.
    """
}

#Preview {
    NavigationStack {
        SettingsHubView()
    }
    .preferredColorScheme(.dark)
}
