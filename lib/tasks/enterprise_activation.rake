namespace :enterprise do
	desc 'Força configuração global de instalação para Enterprise (idempotente)'
	task activate_installation: :environment do
		puts '==> Ativando configuração global Enterprise'

		plan = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
		plan.value = 'enterprise'
		plan.save!
		puts "INSTALLATION_PRICING_PLAN=enterprise ✅"

		qty = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
		qty.value = (qty.value.presence || 10000).to_i
		qty.save!
		puts "INSTALLATION_PRICING_PLAN_QUANTITY=#{qty.value} ✅"

		legacy_qty = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_QUANTITY')
		legacy_qty.value = qty.value
		legacy_qty.save!
		puts "INSTALLATION_QUANTITY=#{legacy_qty.value} ✅"
	end

	desc 'Define plan_name e habilita recursos premium em uma conta específica (ACCOUNT_ID ou DOMAIN_REQUIRED)'
	task :activate_account, [:account_id] => :environment do |_t, args|
		account = if args[:account_id]
								Account.find_by(id: args[:account_id])
							else
								Account.first
							end

		abort 'Nenhuma conta encontrada' unless account

		puts "==> Ativando conta ##{account.id} (#{account.name}) para Enterprise"

		custom = account.custom_attributes || {}
		custom['plan_name'] = 'Enterprise'
		account.custom_attributes = custom

		startup = %w[
			inbound_emails help_center campaigns team_management channel_twitter channel_facebook channel_email channel_instagram captain_integration
		]
		business = %w[sla custom_roles]
		enterprise = %w[audit_logs disable_branding]

		account.disable_features(*(startup + business + enterprise))
		account.enable_features(*(startup + business + enterprise))

		account.save!
		puts 'Plano e recursos premium aplicados à conta ✅'
	end

	desc 'Habilita todos os flags premium em todas as contas (útil para instalações multi-conta)'
	task enable_premium_features: :environment do
		puts '==> Habilitando recursos premium em todas as contas'
		startup = %w[
			inbound_emails help_center campaigns team_management channel_twitter channel_facebook channel_email channel_instagram captain_integration
		]
		business = %w[sla custom_roles]
		enterprise = %w[audit_logs disable_branding]

		Account.find_each do |account|
			account.disable_features(*(startup + business + enterprise))
			account.enable_features(*(startup + business + enterprise))
			account.custom_attributes = (account.custom_attributes || {}).merge('plan_name' => 'Enterprise')
			account.save!
			puts "Conta ##{account.id} atualizada ✅"
		end
	end

	desc 'Verifica o estado Enterprise e imprime um resumo amigável'
	task verify: :environment do
		plan = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')&.value
		qty = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')&.value
		puts '=== Verificação Enterprise ==='
		puts "Plano: #{plan || 'indefinido'}"
		puts "Quantidade: #{qty || '0'}"

		is_enterprise = ChatwootApp.enterprise? && ChatwootHub.pricing_plan == 'enterprise'
		puts "Status: #{is_enterprise ? '✅ ATIVADO' : '❌ DESATIVADO'}"

		if is_enterprise
			sample = Account.first
			if sample
				features = %w[audit_logs sla custom_roles captain_integration disable_branding]
				flags = features.map { |f| [f, sample.feature_enabled?(f)] }.to_h
				puts "Conta ##{sample.id} features: #{flags}"
			end
		end
	end

	desc 'Bootstrap completo: ativa instalação + habilita premium em contas + verifica (idempotente)'
	task bootstrap: :environment do
		Rake::Task['enterprise:activate_installation'].invoke
		Rake::Task['enterprise:enable_premium_features'].reenable
		Rake::Task['enterprise:enable_premium_features'].invoke
		Rake::Task['enterprise:verify'].reenable
		Rake::Task['enterprise:verify'].invoke
	end
end
