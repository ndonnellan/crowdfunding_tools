##
## SCRAPE.RB
##
## ----------
## Crawl www.indiegogo.com for projects related to a search term and collect
## a few important details: name, funding goal, funding so far and days left.
##
## 2013-01-15: Very rudimentary and little error handling, but seems to work for meow


require 'nokogiri'
require 'open-uri'

class Project
	attr_accessor :name, :partial_url, :raised, :funding_goal, :days_left

	def initialize(name, partial_url)
		@name = name
		@partial_url = partial_url
	end

	def getInfo()
		full_url = "http://www.indiegogo.com/" + @partial_url
		local_doc = Nokogiri::HTML(open(full_url))
		@raised = local_doc.css('.money-raised .amount.medium.clearfix')[0].content
		@funding_goal = local_doc.css('.money-raised.goal')[0].content.match(/(\$*\d*,*\d+)+/)[0]
		@days_left = local_doc.css('.days-left .amount.bold')[0].content
	end
end

class ProjectList
	attr_accessor :list
	def initialize()
		@list = []
	end

	def scrapeResultsPage(doc)

		project_names = []
		url = []

		doc.css('.fl.badge.rounded.shadow').each do |project_div|
			project_names << project_div.css('.project-details a.name.bold.notranslate')[0].content
			url << project_div.css('.image.clearfix a')[0]['href']
		end

		new_list = []
		for i in 0..project_names.length
			unless project_names[i].nil?
				new_list << Project.new(project_names[i], url[i])
			end
		end

		return new_list
	end

	def getProjectsByTerm(search_term, all_pages_wanted = false)
		doc = Nokogiri::HTML(open(
			"http://www.indiegogo.com/projects?utf8=%E2%9C%93&filter_text=#{search_term}&search_submit=Search"))
		# Get the first page of results
		@list = scrapeResultsPage(doc)

		if all_pages_wanted
			# Get max number of pages in query result
			max_pages = self.numPages(doc)
			print "#{max_pages} pages found, scraping "
			for i in 1..max_pages
				print "."
				@list.concat(
					self.scrapeResultsPage(
						self.getSpecificPage(search_term, i+1)))
			end
			print "\n"
		end

		return nil
	end

	def numPages(doc)
		return doc.css('.browse_pagination a')[-2].content.to_i
	end

	def getSpecificPage(search_term, page_number)
		url = "http://www.indiegogo.com/projects?" +
			"filter_text=#{search_term}&" +
			"pbigg_id=1&" +
			"pg_num=#{page_number}&" +
			"search_submit=Search&" +
			"utf8=%E2%9C%93"

		begin
			return Nokogiri::HTML(open(url))
		rescue
			print "\n"
			puts "Invalid URL: #{url}"
		end
	end

	def getProjectDetails()
		for project in @list
			print "."
			project.getInfo()
		end
		print "\n"
		return nil
	end

	def printToFile(filename)
		File.open(filename,'w') do |f|
			idx = 1
			for project in @list
				f.puts "#{idx}, #{project.raised}, #{project.funding_goal}, #{project.days_left}"
				idx += 1
			end
		end
	end
end

