# Use the official Tomcat image with JDK 11
FROM tomcat:9.0-jdk11

# Copy the PetClinic WAR file to the Tomcat webapps directory
COPY target/*.war /usr/local/tomcat/webapps/petclinic.war

# Expose the default Tomcat port
EXPOSE 8080

# Start the Tomcat server
CMD ["catalina.sh", "run"]
