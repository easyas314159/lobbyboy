package main

import (
	"fmt"
	"regexp"
)

var (
	ID   *regexp.Regexp = regexp.MustCompilePOSIX("^[_a-zA-Z0-9]+$")
	E164 *regexp.Regexp = regexp.MustCompilePOSIX("^\\+[1-9][0-9]{1,14}$")
)

type NumberSet map[string]struct{}

type Directory struct {
	numbers       NumberSet
	nameToNumbers map[string]NumberSet
}

func (ns *NumberSet) Add(values ...string) {
	for _, value := range values {
		(*ns)[value] = struct{}{}
	}
}

func (ns *NumberSet) Remove(values ...string) {
	for _, value := range values {
		delete((*ns), value)
	}
}

func (ns *NumberSet) Has(value string) bool {
	_, ok := (*ns)[value]
	return ok
}

func (ns *NumberSet) Values() []string {
	values := make([]string, 0, len((*ns)))
	for k := range *ns {
		values = append(values, k)
	}
	return values
}

func NewDirectory() *Directory {
	return &Directory{
		numbers:       make(NumberSet),
		nameToNumbers: make(map[string]NumberSet),
	}
}

func (d *Directory) Add(name, number string) error {
	if !ID.MatchString(name) {
		return fmt.Errorf("%s contains characters other than 0-9, a-z, A-z, ., and _", name)
	}
	if !E164.MatchString(number) {
		return fmt.Errorf("%s is not a valid E.164 number", number)
	}

	d.numbers.Add(number)
	ns, ok := d.nameToNumbers[name]
	if !ok {
		ns = make(NumberSet)
		d.nameToNumbers[name] = ns
	}
	ns.Add(number)

	return nil
}

func (d *Directory) Lookup(names ...string) []string {
	numbers := make([]string, 0)
	for _, name := range names {
		ns, ok := d.nameToNumbers[name]
		if ok {
			// The directory contains one or more named numbers
			numbers = append(numbers, ns.Values()...)
			continue
		}

		if E164.MatchString(name) {
			// The name is already a number
			numbers = append(numbers, name)
			continue
		}

		// Ignore anything that doesn't match
	}
	return numbers
}
