#!/usr/bin/env ruby
# encoding: utf-8
require 'savon'
require 'csv'

csvHeaders = ['numar', 'numar_vechi', 'data', 'institutie', 'departament',
              'categorie_caz', 'stadiu_procesual', 'obiect', 'data_modificare','nume','calitate_parte','solutie']
# csvPartHeaders = ['numar', 'numar_vechi', 'data', 'institutie', 'departament',
#                               'categorie_caz', 'stadiu_procesual', 'obiect', 'data_modificare']
# CITIRE INSTITUTII  ========================
f = File.open("institutii.txt", "r")
institutii = [] #
f.each_line do |line|
  line = line.strip || line
  institutii << line
  fileName = line + ".csv"
  if (!File.exist?(fileName))
    File.open(fileName, 'w')
  end
end
f.close
#SFARSIT CITIRE INSTITUTII ==================


client = Savon.client(wsdl: 'http://portalquery.just.ro/query.asmx?WSDL')
client.operations

#CITIRE DOSARE / INSTITUTIE / DATA START / DATA STOP / INTERVAL 15 ZILE
institutii.each do |inst|
  startDate = Date.new(2000, 1, 1)
  stopDate = Date.today
  #stopDate = Date.new(2010, 1, 9)
  # binding.pry
  instFile = inst + '.csv'
  CSV.open(instFile, 'w',
           :write_headers=> true,
           :headers => csvHeaders ) do |csv_object|
             while (startDate < stopDate) do
               start = startDate.strftime('%Y-%m-%d')
               startDate += 8
               stop = startDate.strftime('%Y-%m-%d')
               response = client.call(:cautare_dosare, message:
                                      {institutie: inst, data_start: start, data_stop: stop})
               if response.body[:cautare_dosare_response][:cautare_dosare_result] != nil
                 dosare = response.body[:cautare_dosare_response][:cautare_dosare_result][:dosar] 
                 if  dosare != nil
                   dosare.each do |dosar|

                     dosarParteNume = ""
                     dosarCalitateParte = ""
                   #  begin 
                       if dosar.class == Hash
                         dosar_parti = dosar[:parti]
                         dosar_sedinte = dosar[:sedinte]
                       else
                         dosar_parti = dosar[1]
                         dosar_sedinte = dosar[3]
                       end
                       if dosar_parti && (dosar_parti.class == Array || dosar_parti.class == Hash)
                         [dosar_parti].flatten.each do |parti|
                           if parti[:dosar_parte]
                             [parti[:dosar_parte]].flatten.each do |parte|
                               dosarParteNume << parte[:nume] + "#" if parte[:nume]
                               dosarCalitateParte << parte[:calitate_parte] + "#" if parte[:calitate_parte]
                             end
                           end
                         end
                       end


                       dosarsedintasolutie = ""
                       dosarsedintasolutiesumar = ""
                       if dosar_sedinte && dosar_sedinte[:dosar_sedinta]
                         [dosar_sedinte[:dosar_sedinta]].flatten.each do |sedinta|
                           dosarsedintasolutie << sedinta[:solutie] + "#" if sedinta[:solutie]
                           dosarsedintasolutiesumar << sedinta[:solutie_sumar] + "#" if sedinta[:solutie_sumar]
                         end
                       end

                       # Acum le punem pe toate intr-un singur loc
                       if dosar.class == Hash
                         toPut = [dosar[:numar], dosar[:numar_vechi],
                                  dosar[:data], dosar[:institutie],
                                  dosar[:departament],
                                  dosar[:categorie_caz],
                                  dosar[:stadiu_procesual],
                                  dosar[:obiect].to_s.gsub("\n",' '),
                                  dosar[:data_modificare],
                                  dosarParteNume,
                                  dosarCalitateParte,
                                  dosarsedintasolutie,
                                  dosarsedintasolutiesumar]
                         csv_object << toPut
                         puts dosar[:numar]
						
                       end
                   #  rescue
                      # binding.pry
                    # end
                   end
                 end
               end
             end
           end
end
